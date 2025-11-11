import 'dart:convert';
import 'dart:io';
import 'migration_config.dart';

/// Script interactif pour attribuer manuellement les photos aux utilisateurs
void main() async {
  print('═══════════════════════════════════════════════════════');
  print('🎯 ATTRIBUTION INTERACTIVE DES PHOTOS');
  print('═══════════════════════════════════════════════════════');
  print('');
  print('Ce script va vous montrer chaque photo et vous demander');
  print('à quel utilisateur elle appartient.');
  print('');

  try {
    final assigner = InteractivePhotoAssigner();
    await assigner.assignPhotos();
  } catch (e, stackTrace) {
    print('');
    print('❌ ERREUR: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

class InteractivePhotoAssigner {
  final String endpoint = MigrationConfig.cloudEndpoint;
  final String projectId = MigrationConfig.cloudProjectId;
  final String apiKey = MigrationConfig.cloudApiKey;
  final String databaseId = MigrationConfig.cloudDatabaseId;

  // Pour afficher les images, on utilise l'URL publique
  String getPhotoViewUrl(String fileId) {
    return '$endpoint/storage/buckets/${MigrationConfig.cloudBucketId}/files/$fileId/view?project=$projectId';
  }

  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$endpoint$path');
      final request = await client.openUrl(method, uri);

      request.headers.set('Content-Type', 'application/json');
      request.headers.set('X-Appwrite-Project', projectId);
      request.headers.set('X-Appwrite-Key', apiKey);

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('HTTP ${response.statusCode}: $responseBody');
      }
    } finally {
      client.close();
    }
  }

  Future<void> assignPhotos() async {
    print('📡 Connexion à Appwrite Cloud...');
    print('');

    // 1. Récupérer tous les utilisateurs
    print('👥 Récupération des utilisateurs...');
    final usersResponse = await _makeRequest(
      'GET',
      '/databases/$databaseId/collections/users/documents?limit=100',
    );

    final users = usersResponse['documents'] as List;
    print('✅ ${users.length} utilisateurs trouvés');
    print('');

    // Créer une liste numérotée des utilisateurs
    print('═══════════════════════════════════════════════════════');
    print('LISTE DES UTILISATEURS');
    print('═══════════════════════════════════════════════════════');

    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      final name = user['name'] ?? 'N/A';
      final email = user['email'] ?? 'N/A';
      final userId = user['\$id'];
      print('${i + 1}. $name ($email)');
      print('   ID: $userId');
    }
    print('');

    // 2. Récupérer toutes les photos non attribuées ou mal attribuées
    print('📸 Récupération des photos...');
    final photosResponse = await _makeRequest(
      'GET',
      '/databases/$databaseId/collections/photos/documents?limit=200',
    );

    final allPhotos = photosResponse['documents'] as List;

    // Filtrer les photos qui ne correspondent pas aux photoUrls des utilisateurs
    List<Map<String, dynamic>> photosToAssign = [];

    for (var photo in allPhotos) {
      final fileId = photo['fileId'];
      final currentUserId = photo['userID'];

      // Vérifier si ce fileId est dans les photoUrls de l'utilisateur actuel
      final currentUser = users.firstWhere(
        (u) => u['\$id'] == currentUserId,
        orElse: () => {},
      );

      if (currentUser.isEmpty) {
        photosToAssign.add(photo);
        continue;
      }

      final photoUrls = List<String>.from(currentUser['photoUrls'] ?? []);
      if (!photoUrls.contains(fileId)) {
        photosToAssign.add(photo);
      }
    }

    print('✅ ${allPhotos.length} photos trouvées');
    print('⚠️ ${photosToAssign.length} photos à attribuer/corriger');
    print('');

    if (photosToAssign.isEmpty) {
      print('🎉 Toutes les photos sont déjà correctement attribuées!');
      return;
    }

    // 3. Pour chaque photo, demander à qui l'attribuer
    int corrected = 0;
    int skipped = 0;

    for (int i = 0; i < photosToAssign.length; i++) {
      final photo = photosToAssign[i];
      final photoId = photo['\$id'];
      final fileId = photo['fileId'];
      final currentUserId = photo['userID'];

      print('═══════════════════════════════════════════════════════');
      print('Photo ${i + 1}/${photosToAssign.length}');
      print('═══════════════════════════════════════════════════════');
      print('Photo ID: $photoId');
      print('File ID: $fileId');
      print('User ID actuel: $currentUserId');
      print('');
      print('🔗 URL pour voir la photo:');
      print(getPhotoViewUrl(fileId));
      print('');
      print('Ouvrez cette URL dans votre navigateur pour voir la photo.');
      print('');
      print('À quel utilisateur appartient cette photo?');
      print('Entrez le numéro (1-${users.length}), ou "s" pour skip, ou "q" pour quitter:');

      final input = stdin.readLineSync();

      if (input == null || input.trim().isEmpty) {
        print('⏭️ Skipped');
        skipped++;
        print('');
        continue;
      }

      if (input.toLowerCase() == 'q') {
        print('👋 Arrêt du script');
        break;
      }

      if (input.toLowerCase() == 's') {
        print('⏭️ Skipped');
        skipped++;
        print('');
        continue;
      }

      final userIndex = int.tryParse(input);
      if (userIndex == null || userIndex < 1 || userIndex > users.length) {
        print('❌ Numéro invalide, skipped');
        skipped++;
        print('');
        continue;
      }

      final selectedUser = users[userIndex - 1];
      final selectedUserId = selectedUser['\$id'];
      final selectedUserName = selectedUser['name'];

      print('✅ Attribution à: $selectedUserName');

      // Mettre à jour la photo
      try {
        await _makeRequest(
          'PATCH',
          '/databases/$databaseId/collections/photos/documents/$photoId',
          body: {'userID': selectedUserId},
        );

        print('   ✅ Photo mise à jour');

        // Ajouter le fileId aux photoUrls de l'utilisateur
        final currentPhotoUrls = List<String>.from(selectedUser['photoUrls'] ?? []);
        if (!currentPhotoUrls.contains(fileId)) {
          currentPhotoUrls.add(fileId);

          await _makeRequest(
            'PATCH',
            '/databases/$databaseId/collections/users/documents/$selectedUserId',
            body: {'photoUrls': currentPhotoUrls},
          );

          print('   ✅ photoUrls mis à jour pour $selectedUserName');
        }

        corrected++;
      } catch (e) {
        print('   ❌ Erreur: $e');
      }

      print('');
    }

    print('═══════════════════════════════════════════════════════');
    print('📊 RÉSUMÉ');
    print('═══════════════════════════════════════════════════════');
    print('Total photos traitées: ${photosToAssign.length}');
    print('✅ Corrigées: $corrected');
    print('⏭️ Skipped: $skipped');
    print('');
    print('🎉 Terminé!');
  }
}
