import 'dart:convert';
import 'dart:io';
import 'migration_config.dart';

void main() async {
  print('═══════════════════════════════════════════════════════');
  print('🗑️ SUPPRESSION DES VIDÉOS ORPHELINES');
  print('═══════════════════════════════════════════════════════');
  print('');

  try {
    final deleter = OrphanVideoDeleter();
    await deleter.deleteOrphanVideos();
  } catch (e) {
    print('❌ ERREUR: $e');
    exit(1);
  }
}

class OrphanVideoDeleter {
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
        // DELETE peut retourner une réponse vide (204 No Content)
        if (responseBody.isEmpty || method == 'DELETE') {
          return {'status': 'success'};
        }
        return jsonDecode(responseBody);
      } else {
        throw Exception('HTTP ${response.statusCode}: $responseBody');
      }
    } finally {
      client.close();
    }
  }

  Future<void> deleteOrphanVideos() async {
    print('📹 Récupération des documents vidéo...');
    final videosResponse = await _makeRequest(
      'GET',
      '/databases/$databaseId/collections/videos/documents?limit=100',
    );

    final videos = videosResponse['documents'] as List;
    print('✅ ${videos.length} documents vidéo trouvés\n');

    List<String> orphanIds = [];

    // Vérifier chaque vidéo
    for (var video in videos) {
      final videoId = video['\$id'];
      final fileId = video['fileId'];

      try {
        await _makeRequest('GET', '/storage/buckets/$bucketId/files/$fileId');
        print('✅ Vidéo $videoId - fichier existe');
      } catch (e) {
        print('❌ Vidéo $videoId - fichier MANQUANT (orphelin)');
        orphanIds.add(videoId);
      }
    }

    print('');
    print('═══════════════════════════════════════════════════════');
    print('📊 RÉSUMÉ');
    print('═══════════════════════════════════════════════════════');
    print('Total vidéos: ${videos.length}');
    print('Orphelines trouvées: ${orphanIds.length}');
    print('');

    if (orphanIds.isEmpty) {
      print('🎉 Aucune vidéo orpheline!');
      return;
    }

    print('⚠️ ${orphanIds.length} vidéos orphelines à supprimer');
    print('');
    stdout.write('Voulez-vous les supprimer? (y/n): ');

    final confirm = stdin.readLineSync()?.trim().toLowerCase() ?? '';

    if (confirm != 'y' && confirm != 'yes') {
      print('❌ Annulé');
      return;
    }

    print('');
    print('🗑️ Suppression en cours...');
    int deleted = 0;

    for (var videoId in orphanIds) {
      try {
        await _makeRequest(
          'DELETE',
          '/databases/$databaseId/collections/videos/documents/$videoId',
        );
        print('✅ Vidéo $videoId supprimée');
        deleted++;

        // Rate limiting
        await Future.delayed(Duration(milliseconds: 200));
      } catch (e) {
        print('❌ Erreur suppression $videoId: $e');
      }
    }

    print('');
    print('═══════════════════════════════════════════════════════');
    print('✅ Suppression terminée');
    print('═══════════════════════════════════════════════════════');
    print('Vidéos supprimées: $deleted/${orphanIds.length}');
    print('');
    print('Les utilisateurs peuvent maintenant uploader de nouvelles vidéos.');
  }
}
