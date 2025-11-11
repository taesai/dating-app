import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'migration_config.dart';

/// Vérifie quels fichiers photos existent réellement dans le bucket
class PhotoFileChecker {
  final String endpoint = MigrationConfig.cloudEndpoint;
  final String projectId = MigrationConfig.cloudProjectId;
  final String apiKey = MigrationConfig.cloudApiKey;
  final String databaseId = MigrationConfig.cloudDatabaseId;
  final String bucketId = MigrationConfig.cloudBucketId;

  Future<Map<String, dynamic>> _makeRequest(String method, String path,
      {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$endpoint$path');

    final headers = {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
    };

    http.Response response;
    switch (method) {
      case 'GET':
        response = await http.get(url, headers: headers);
        break;
      case 'DELETE':
        response = await http.delete(url, headers: headers);
        break;
      default:
        throw Exception('Méthode HTTP non supportée: $method');
    }

    final responseBody = response.body;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.isEmpty || method == 'DELETE') {
        return {'status': 'success'};
      }
      return jsonDecode(responseBody);
    } else {
      if (responseBody.isEmpty) {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
      final error = jsonDecode(responseBody);
      throw Exception('${error['message']} (${error['code']})');
    }
  }

  Future<void> checkPhotoFiles() async {
    print('═══════════════════════════════════════════════════════');
    print('🔍 VÉRIFICATION DES FICHIERS PHOTOS');
    print('═══════════════════════════════════════════════════════');
    print('Endpoint: $endpoint');
    print('Bucket: $bucketId');
    print('Database: $databaseId');
    print('═══════════════════════════════════════════════════════\n');

    int totalPhotos = 0;
    int existsCount = 0;
    int missingCount = 0;
    List<Map<String, String>> missingPhotos = [];

    try {
      // 1. Récupérer tous les documents photos
      print('📥 Récupération des documents photos...');
      final photosResponse = await _makeRequest(
        'GET',
        '/databases/$databaseId/collections/photos/documents?limit=100',
      );

      final photos = photosResponse['documents'] as List;
      totalPhotos = photos.length;
      print('✅ $totalPhotos documents photos trouvés\n');

      // 2. Vérifier l'existence de chaque fichier dans le bucket
      print('🔍 Vérification des fichiers dans le bucket...\n');

      for (var photo in photos) {
        final photoId = photo['\$id'];
        final fileId = photo['fileId'];
        final userId = photo['userID'];

        try {
          // Essayer de récupérer les métadonnées du fichier
          await _makeRequest(
            'GET',
            '/storage/buckets/$bucketId/files/$fileId',
          );
          existsCount++;
          print('✅ Photo $photoId (fileId: $fileId, user: $userId) - EXISTE');
        } catch (e) {
          missingCount++;
          missingPhotos.add({
            'photoId': photoId,
            'fileId': fileId,
            'userId': userId,
          });
          print('❌ Photo $photoId (fileId: $fileId, user: $userId) - MANQUANT');
          print('   Erreur: $e\n');
        }
      }

      // 3. Afficher le résumé
      print('\n═══════════════════════════════════════════════════════');
      print('📊 RÉSUMÉ');
      print('═══════════════════════════════════════════════════════');
      print('Total de documents photos: $totalPhotos');
      print('✅ Fichiers existants: $existsCount');
      print('❌ Fichiers manquants: $missingCount');
      print('═══════════════════════════════════════════════════════\n');

      if (missingPhotos.isNotEmpty) {
        print('❌ Photos orphelines (documents sans fichier):');
        for (var photo in missingPhotos) {
          print('   - Document: ${photo['photoId']}');
          print('     FileId: ${photo['fileId']}');
          print('     UserId: ${photo['userId']}');
        }
      }
    } catch (e, stackTrace) {
      print('💥 Erreur fatale: $e');
      print('Stack trace: $stackTrace');
    }
  }
}

void main() async {
  final checker = PhotoFileChecker();
  await checker.checkPhotoFiles();
}
