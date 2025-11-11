import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'migration_config.dart';

/// Supprime les documents photos qui n'ont pas de fichier correspondant dans le bucket
class OrphanPhotoDeleter {
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

  Future<void> deleteOrphanPhotos() async {
    print('═══════════════════════════════════════════════════════');
    print('🗑️  SUPPRESSION DES PHOTOS ORPHELINES');
    print('═══════════════════════════════════════════════════════');
    print('Endpoint: $endpoint');
    print('Bucket: $bucketId');
    print('Database: $databaseId');
    print('═══════════════════════════════════════════════════════\n');

    List<String> orphanIds = [];

    try {
      // 1. Récupérer tous les documents photos
      print('📥 Récupération des documents photos...');
      final photosResponse = await _makeRequest(
        'GET',
        '/databases/$databaseId/collections/photos/documents?limit=100',
      );

      final photos = photosResponse['documents'] as List;
      print('✅ ${photos.length} documents photos trouvés\n');

      // 2. Identifier les photos orphelines
      print('🔍 Identification des photos orphelines...\n');

      for (var photo in photos) {
        final photoId = photo['\$id'];
        final fileId = photo['fileId'];
        final userId = photo['userID'];

        try {
          // Vérifier si le fichier existe
          await _makeRequest(
            'GET',
            '/storage/buckets/$bucketId/files/$fileId',
          );
          print('✅ Photo $photoId - fichier existe');
        } catch (e) {
          orphanIds.add(photoId);
          print('❌ Photo $photoId (fileId: $fileId, user: $userId) - ORPHELINE');
        }
      }

      print('\n═══════════════════════════════════════════════════════');
      print('📊 ${orphanIds.length} photos orphelines trouvées');
      print('═══════════════════════════════════════════════════════\n');

      if (orphanIds.isEmpty) {
        print('✅ Aucune photo orpheline à supprimer');
        return;
      }

      // 3. Demander confirmation
      print('⚠️  Voulez-vous supprimer ces ${orphanIds.length} documents photos orphelins?');
      print('   Tapez "oui" pour confirmer: ');
      final confirmation = stdin.readLineSync();

      if (confirmation?.toLowerCase() != 'oui') {
        print('❌ Suppression annulée');
        return;
      }

      // 4. Supprimer les documents orphelins
      print('\n🗑️  Suppression des documents orphelins...\n');
      int deletedCount = 0;
      int errorCount = 0;

      for (var photoId in orphanIds) {
        try {
          await _makeRequest(
            'DELETE',
            '/databases/$databaseId/collections/photos/documents/$photoId',
          );
          deletedCount++;
          print('✅ Document $photoId supprimé');
        } catch (e) {
          errorCount++;
          print('❌ Erreur suppression document $photoId: $e');
        }
      }

      // 5. Afficher le résumé final
      print('\n═══════════════════════════════════════════════════════');
      print('📊 RÉSUMÉ FINAL');
      print('═══════════════════════════════════════════════════════');
      print('Documents supprimés: $deletedCount');
      print('Erreurs: $errorCount');
      print('═══════════════════════════════════════════════════════');

      if (errorCount > 0) {
        print('⚠️ Suppression terminée avec des erreurs');
      } else {
        print('🎉 Suppression terminée avec succès!');
      }
    } catch (e, stackTrace) {
      print('💥 Erreur fatale: $e');
      print('Stack trace: $stackTrace');
    }
  }
}

void main() async {
  final deleter = OrphanPhotoDeleter();
  await deleter.deleteOrphanPhotos();
}
