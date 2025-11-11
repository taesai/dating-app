import 'dart:convert';
import 'dart:io';
import 'migration_config.dart';

void main() async {
  print('🔍 Vérification des fichiers vidéo dans le bucket cloud...\n');

  try {
    final checker = VideoFileChecker();
    await checker.checkVideoFiles();
  } catch (e) {
    print('❌ ERREUR: $e');
    exit(1);
  }
}

class VideoFileChecker {
  final String endpoint = MigrationConfig.cloudEndpoint;
  final String projectId = MigrationConfig.cloudProjectId;
  final String apiKey = MigrationConfig.cloudApiKey;
  final String databaseId = MigrationConfig.cloudDatabaseId;
  final String bucketId = MigrationConfig.cloudBucketId;

  Future<Map<String, dynamic>> _makeRequest(String method, String path) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$endpoint$path');
      final request = await client.openUrl(method, uri);

      request.headers.set('Content-Type', 'application/json');
      request.headers.set('X-Appwrite-Project', projectId);
      request.headers.set('X-Appwrite-Key', apiKey);

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

  Future<void> checkVideoFiles() async {
    // 1. Récupérer tous les documents vidéo
    print('📹 Récupération des documents vidéo...');
    final videosResponse = await _makeRequest(
      'GET',
      '/databases/$databaseId/collections/videos/documents?limit=100',
    );

    final videos = videosResponse['documents'] as List;
    print('✅ ${videos.length} documents vidéo trouvés\n');

    // 2. Vérifier si les fichiers existent dans le bucket
    int existsCount = 0;
    int missingCount = 0;

    for (var video in videos) {
      final videoId = video['\$id'];
      final fileId = video['fileId'];
      final userId = video['userId'];

      print('Vidéo: $videoId (User: $userId)');
      print('  FileID: $fileId');

      try {
        await _makeRequest('GET', '/storage/buckets/$bucketId/files/$fileId');
        print('  ✅ Fichier existe\n');
        existsCount++;
      } catch (e) {
        print('  ❌ Fichier MANQUANT\n');
        missingCount++;
      }
    }

    print('═══════════════════════════════════════════════════════');
    print('📊 RÉSUMÉ');
    print('═══════════════════════════════════════════════════════');
    print('Total vidéos: ${videos.length}');
    print('✅ Fichiers existants: $existsCount');
    print('❌ Fichiers manquants: $missingCount');
    print('');

    if (missingCount > 0) {
      print('⚠️ PROBLÈME: $missingCount fichiers vidéo manquants!');
      print('Les fichiers n\'ont pas été migrés depuis le backend local.');
      print('');
      print('SOLUTIONS:');
      print('1. Supprimer les documents vidéo orphelins (recommandé)');
      print('2. Migrer les fichiers depuis le backend local (complexe)');
      print('3. Demander aux utilisateurs de ré-uploader leurs vidéos');
    } else {
      print('🎉 Tous les fichiers vidéo sont présents!');
    }
  }
}
