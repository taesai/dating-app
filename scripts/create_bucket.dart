import 'dart:io';
import 'dart:convert';
import 'migration_config.dart';

/// Script pour créer le bucket de stockage dans Appwrite Cloud
void main() async {
  print('═══════════════════════════════════════════════════════');
  print('🗄️ CRÉATION DU BUCKET DE STOCKAGE APPWRITE CLOUD');
  print('═══════════════════════════════════════════════════════');
  print('');

  final creator = AppwriteBucketCreator();

  try {
    await creator.createMediasBucket();

    print('\n═══════════════════════════════════════════════════════');
    print('✅ BUCKET CRÉÉ AVEC SUCCÈS !');
    print('═══════════════════════════════════════════════════════');
    print('\nProchaine étape:');
    print('  → Vérifiez dans Appwrite Console que le bucket existe');
    print('  → Configurez les permissions si nécessaire');
    print('  → Prêt à migrer les données !');

  } catch (e, stackTrace) {
    print('\n❌ ERREUR: $e');
    print('Stack trace: $stackTrace');
  }
}

class AppwriteBucketCreator {
  final String endpoint = MigrationConfig.cloudEndpoint;
  final String projectId = MigrationConfig.cloudProjectId;
  final String apiKey = MigrationConfig.cloudApiKey;

  final HttpClient _httpClient = HttpClient();

  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String path,
    Map<String, dynamic>? body,
  ) async {
    final uri = Uri.parse('$endpoint$path');

    HttpClientRequest request;
    if (method == 'POST') {
      request = await _httpClient.postUrl(uri);
    } else {
      throw Exception('Unsupported method: $method');
    }

    request.headers.add('X-Appwrite-Project', projectId);
    request.headers.add('X-Appwrite-Key', apiKey);
    request.headers.add('Content-Type', 'application/json');

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
  }

  Future<void> createMediasBucket() async {
    print('📦 Création du bucket "medias"...');

    try {
      final result = await _makeRequest('POST', '/storage/buckets', {
        'bucketId': 'medias',
        'name': 'medias',
        'permissions': [
          'read("any")',
          'create("users")',
          'update("users")',
          'delete("users")',
        ],
        'fileSecurity': true,
        'enabled': true,
        'maximumFileSize': 50000000, // 50 MB
        'allowedFileExtensions': ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi', 'webm'],
        'compression': 'gzip',
        'encryption': true,
        'antivirus': true,
      });

      print('   ✅ Bucket créé: ${result['\$id']}');
      print('   📏 Taille max: 50 MB');
      print('   📎 Extensions: jpg, jpeg, png, gif, mp4, mov, avi, webm');
      print('   🔒 Compression: activée');
      print('   🔐 Encryption: activée');
      print('   🛡️ Antivirus: activé');

    } catch (e) {
      if (e.toString().contains('409')) {
        print('   ⚠️ Bucket déjà existant');
      } else {
        rethrow;
      }
    }
  }
}
