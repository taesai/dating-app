import 'dart:convert';
import 'dart:io';
import 'migration_config.dart';

/// Script pour corriger les propriétaires (userID) des photos
/// en se basant sur les photoUrls des utilisateurs
void main() async {
  print('═══════════════════════════════════════════════════════');
  print('🔧 CORRECTION DES PROPRIÉTAIRES DE PHOTOS');
  print('═══════════════════════════════════════════════════════');
  print('');

  try {
    final fixer = PhotoOwnerFixer();
    await fixer.fixPhotoOwners();
    print('');
    print('✅ CORRECTION TERMINÉE');
  } catch (e) {
    print('');
    print('❌ ERREUR: $e');
    exit(1);
  }
}

class PhotoOwnerFixer {
  final String endpoint = MigrationConfig.cloudEndpoint;
  final String projectId = MigrationConfig.cloudProjectId;
  final String apiKey = MigrationConfig.cloudApiKey;
  final String databaseId = MigrationConfig.cloudDatabaseId;
  final String usersCollectionId = 'users';
  final String photosCollectionId = 'photos';

  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$endpoint$path');
      final request = await client.openUrl(method, uri);

      // Headers
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('X-Appwrite-Project', projectId);
      request.headers.set('X-Appwrite-Key', apiKey);

      // Body
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

  Future<void> fixPhotoOwners() async {
    print('📡 Connexion à Appwrite Cloud...');
    print('');

    // 1. Récupérer tous les utilisateurs avec leurs photoUrls
    print('👥 Récupération de tous les utilisateurs...');
    final usersResponse = await _makeRequest(
      'GET',
      '/databases/$databaseId/collections/$usersCollectionId/documents?limit=100',
    );

    final users = usersResponse['documents'] as List;
    print('✅ ${users.length} utilisateurs trouvés');
    print('');

    // 2. Créer une map fileId → userId
    print('🗺️ Construction de la map fileId → userId...');
    Map<String, String> fileIdToUserId = {};

    for (var user in users) {
      final userId = user['\$id'];
      final userName = user['name'] ?? 'N/A';
      final photoUrls = List<String>.from(user['photoUrls'] ?? []);

      print('   User: $userName ($userId) → ${photoUrls.length} photos');

      for (var fileId in photoUrls) {
        fileIdToUserId[fileId] = userId;
        print('      $fileId → $userId');
      }
    }

    print('');
    print('✅ Map créée avec ${fileIdToUserId.length} entrées');
    print('');

    // 3. Récupérer toutes les photos
    print('📸 Récupération de toutes les photos...');
    final photosResponse = await _makeRequest(
      'GET',
      '/databases/$databaseId/collections/$photosCollectionId/documents?limit=200',
    );

    final photos = photosResponse['documents'] as List;
    print('✅ ${photos.length} photos trouvées');
    print('');

    // 4. Corriger chaque photo
    int corrected = 0;
    int skipped = 0;
    int errors = 0;

    for (var photo in photos) {
      final photoId = photo['\$id'];
      final fileId = photo['fileId'];
      final currentUserId = photo['userID'];

      final correctUserId = fileIdToUserId[fileId];

      if (correctUserId == null) {
        print('⚠️ Photo $photoId (fileId: $fileId) - Aucun utilisateur trouvé avec ce fileId');
        skipped++;
        continue;
      }

      if (currentUserId == correctUserId) {
        print('✓ Photo $photoId déjà correcte (userId: $currentUserId)');
        skipped++;
        continue;
      }

      print('🔧 Correction photo $photoId:');
      print('   fileId: $fileId');
      print('   Ancien userID: $currentUserId');
      print('   Nouveau userID: $correctUserId');

      try {
        await _makeRequest(
          'PATCH',
          '/databases/$databaseId/collections/$photosCollectionId/documents/$photoId',
          body: {
            'userID': correctUserId,
          },
        );

        print('   ✅ Corrigé');
        corrected++;
      } catch (e) {
        print('   ❌ Erreur: $e');
        errors++;
      }

      print('');

      // Rate limiting
      await Future.delayed(Duration(milliseconds: 200));
    }

    print('═══════════════════════════════════════════════════════');
    print('📊 RÉSUMÉ');
    print('═══════════════════════════════════════════════════════');
    print('Total photos: ${photos.length}');
    print('✅ Corrigées: $corrected');
    print('⏭️ Déjà correctes: $skipped');
    print('❌ Erreurs: $errors');
  }
}
