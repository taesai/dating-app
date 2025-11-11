import 'dart:convert';
import 'dart:io';
import 'migration_config.dart';

/// Script pour corriger l'attribution des photos une par une
/// En affichant clairement chaque photo et en attendant la confirmation
void main() async {
  print('═══════════════════════════════════════════════════════');
  print('🔧 CORRECTION DE L\'ATTRIBUTION DES PHOTOS');
  print('═══════════════════════════════════════════════════════');
  print('');

  try {
    final fixer = PhotoAttributionFixer();
    await fixer.fixAttribution();
  } catch (e, stackTrace) {
    print('');
    print('❌ ERREUR: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

class PhotoAttributionFixer {
  final String endpoint = MigrationConfig.cloudEndpoint;
  final String projectId = MigrationConfig.cloudProjectId;
  final String apiKey = MigrationConfig.cloudApiKey;
  final String databaseId = MigrationConfig.cloudDatabaseId;
  final String bucketId = MigrationConfig.cloudBucketId;

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

  Future<void> fixAttribution() async {
    print('📡 Connexion à Appwrite Cloud...');
    print('');

    // 1. Récupérer tous les utilisateurs
    print('👥 Récupération des utilisateurs...');
    final usersResponse = await _makeRequest(
      'GET',
      '/databases/$databaseId/collections/users/documents?limit=100',
    );

    final users = usersResponse['documents'] as List;
    print('✅ ${users.length} utilisateurs trouvés\n');

    // Afficher la liste des utilisateurs
    print('═══════════════════════════════════════════════════════');
    print('LISTE DES UTILISATEURS');
    print('═══════════════════════════════════════════════════════');

    Map<int, Map<String, dynamic>> userMap = {};

    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      final name = user['name'] ?? 'N/A';
      final email = user['email'] ?? 'N/A';
      final userId = user['\$id'];

      userMap[i + 1] = user;

      print('${i + 1}. $name ($email)');
      print('   UserID: $userId');
    }
    print('═══════════════════════════════════════════════════════\n');

    // 2. Récupérer toutes les photos
    print('📸 Récupération des photos...');
    final photosResponse = await _makeRequest(
      'GET',
      '/databases/$databaseId/collections/photos/documents?limit=200',
    );

    final photos = photosResponse['documents'] as List;
    print('✅ ${photos.length} photos trouvées\n');

    // 3. Traiter chaque photo
    int updated = 0;
    int skipped = 0;

    for (int i = 0; i < photos.length; i++) {
      final photo = photos[i];
      final photoId = photo['\$id'];
      final fileId = photo['fileId'];
      final currentUserId = photo['userID'];

      // Trouver le nom de l'utilisateur actuel
      String currentUserName = 'Unknown';
      try {
        final currentUser = users.firstWhere((u) => u['\$id'] == currentUserId);
        currentUserName = currentUser['name'] ?? 'N/A';
      } catch (e) {
        currentUserName = 'Utilisateur introuvable';
      }

      print('\n═══════════════════════════════════════════════════════');
      print('📸 PHOTO ${i + 1}/${photos.length}');
      print('═══════════════════════════════════════════════════════');
      print('Photo ID: $photoId');
      print('File ID: $fileId');
      print('Propriétaire actuel: $currentUserName (UserID: $currentUserId)');
      print('');
      print('🔗 URL POUR VOIR LA PHOTO:');
      print('$endpoint/storage/buckets/$bucketId/files/$fileId/view?project=$projectId');
      print('');
      print('COPIEZ L\'URL CI-DESSUS DANS VOTRE NAVIGATEUR POUR VOIR LA PHOTO');
      print('');
      print('───────────────────────────────────────────────────────');
      print('À qui appartient cette photo?');
      print('');
      print('Tapez un numéro (1-${users.length}):');
      print('Ou tapez "ok" si la photo est déjà correctement attribuée');
      print('Ou tapez "skip" (s) pour ignorer');
      print('Ou tapez "quit" (q) pour quitter');
      print('───────────────────────────────────────────────────────');
      print('');
      stdout.write('Votre choix: ');

      final input = stdin.readLineSync()?.trim() ?? '';

      if (input.isEmpty) {
        print('⏭️ Skipped (entrée vide)\n');
        skipped++;
        continue;
      }

      if (input.toLowerCase() == 'q' || input.toLowerCase() == 'quit') {
        print('\n👋 Arrêt du script\n');
        break;
      }

      if (input.toLowerCase() == 's' || input.toLowerCase() == 'skip') {
        print('⏭️ Skipped\n');
        skipped++;
        continue;
      }

      if (input.toLowerCase() == 'ok') {
        print('✅ Photo déjà correcte\n');
        skipped++;
        continue;
      }

      // Parser le numéro
      final userNumber = int.tryParse(input);

      if (userNumber == null || !userMap.containsKey(userNumber)) {
        print('❌ Numéro invalide! Skipped\n');
        skipped++;
        continue;
      }

      final selectedUser = userMap[userNumber]!;
      final newUserId = selectedUser['\$id'];
      final newUserName = selectedUser['name'];

      print('');
      print('🎯 Attribution à: $newUserName');
      print('   Nouveau UserID: $newUserId');
      print('');
      stdout.write('Confirmer? (y/n): ');

      final confirm = stdin.readLineSync()?.trim().toLowerCase() ?? '';

      if (confirm != 'y' && confirm != 'yes') {
        print('❌ Annulé\n');
        skipped++;
        continue;
      }

      // Mettre à jour la photo
      try {
        print('🔄 Mise à jour en cours...');

        await _makeRequest(
          'PATCH',
          '/databases/$databaseId/collections/photos/documents/$photoId',
          body: {'userID': newUserId},
        );

        print('✅ Photo mise à jour avec succès');

        // Ajouter le fileId aux photoUrls de l'utilisateur
        final currentPhotoUrls = List<String>.from(selectedUser['photoUrls'] ?? []);

        if (!currentPhotoUrls.contains(fileId)) {
          currentPhotoUrls.add(fileId);

          await _makeRequest(
            'PATCH',
            '/databases/$databaseId/collections/users/documents/$newUserId',
            body: {'photoUrls': currentPhotoUrls},
          );

          print('✅ photoUrls mis à jour pour $newUserName');
        }

        updated++;
        print('');
      } catch (e) {
        print('❌ Erreur: $e\n');
      }
    }

    print('\n═══════════════════════════════════════════════════════');
    print('📊 RÉSUMÉ FINAL');
    print('═══════════════════════════════════════════════════════');
    print('Total photos: ${photos.length}');
    print('✅ Mises à jour: $updated');
    print('⏭️ Skipped/OK: $skipped');
    print('');
    print('🎉 Terminé!');
  }
}
