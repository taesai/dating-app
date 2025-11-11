import 'dart:convert';
import 'dart:io';
import 'migration_config.dart';

/// Script de debug pour voir les données des photos et utilisateurs
void main() async {
  print('═══════════════════════════════════════════════════════');
  print('🔍 DEBUG DES DONNÉES PHOTOS');
  print('═══════════════════════════════════════════════════════');
  print('');

  try {
    final debugger = PhotoDataDebugger();
    await debugger.debugPhotoData();
  } catch (e) {
    print('❌ ERREUR: $e');
    exit(1);
  }
}

class PhotoDataDebugger {
  final String endpoint = MigrationConfig.cloudEndpoint;
  final String projectId = MigrationConfig.cloudProjectId;
  final String apiKey = MigrationConfig.cloudApiKey;
  final String databaseId = MigrationConfig.cloudDatabaseId;

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

  Future<void> debugPhotoData() async {
    print('📡 Connexion à Appwrite Cloud...');
    print('');

    // 1. Récupérer tous les utilisateurs
    print('═══════════════════════════════════════════════════════');
    print('👥 UTILISATEURS');
    print('═══════════════════════════════════════════════════════');

    final usersResponse = await _makeRequest(
      'GET',
      '/databases/$databaseId/collections/users/documents?limit=100',
    );

    final users = usersResponse['documents'] as List;
    print('Total: ${users.length} utilisateurs\n');

    for (var user in users) {
      final userId = user['\$id'];
      final name = user['name'] ?? 'N/A';
      final email = user['email'] ?? 'N/A';
      final photoUrls = user['photoUrls'] ?? [];

      print('┌─ Utilisateur: $name ($email)');
      print('│  ID: $userId');
      print('│  photoUrls: $photoUrls');
      print('│  Nombre de photos: ${photoUrls.length}');
      print('└─');
      print('');
    }

    // 2. Récupérer toutes les photos
    print('═══════════════════════════════════════════════════════');
    print('📸 PHOTOS');
    print('═══════════════════════════════════════════════════════');

    final photosResponse = await _makeRequest(
      'GET',
      '/databases/$databaseId/collections/photos/documents?limit=200',
    );

    final photos = photosResponse['documents'] as List;
    print('Total: ${photos.length} photos\n');

    // Grouper par userId
    Map<String, List<Map<String, dynamic>>> photosByUser = {};
    for (var photo in photos) {
      final userId = photo['userID'] ?? 'unknown';
      if (!photosByUser.containsKey(userId)) {
        photosByUser[userId] = [];
      }
      photosByUser[userId]!.add(photo);
    }

    for (var entry in photosByUser.entries) {
      final userId = entry.key;
      final userPhotos = entry.value;

      // Trouver le nom de l'utilisateur
      var userName = 'Unknown';
      try {
        final user = users.firstWhere((u) => u['\$id'] == userId);
        userName = user['name'] ?? 'N/A';
      } catch (e) {
        userName = 'Utilisateur introuvable';
      }

      print('┌─ Propriétaire: $userName');
      print('│  UserID: $userId');
      print('│  Nombre de photos: ${userPhotos.length}');
      print('│');

      for (var photo in userPhotos) {
        final photoId = photo['\$id'];
        final fileId = photo['fileId'];
        final isApproved = photo['isApproved'] ?? false;

        print('│  ├─ Photo ID: $photoId');
        print('│  │  FileID: $fileId');
        print('│  │  Approuvée: $isApproved');
      }
      print('└─');
      print('');
    }

    print('═══════════════════════════════════════════════════════');
    print('🔍 ANALYSE');
    print('═══════════════════════════════════════════════════════');

    // Comparer les fileIds
    print('\nComparaison des fileIds:\n');

    for (var user in users) {
      final userId = user['\$id'];
      final userName = user['name'] ?? 'N/A';
      final photoUrls = List<String>.from(user['photoUrls'] ?? []);

      if (photoUrls.isEmpty) continue;

      print('User: $userName ($userId)');
      print('  photoUrls dans le profil: $photoUrls');

      // Trouver les photos dans la collection photos
      final userPhotosInCollection = photos.where((p) => p['userID'] == userId).toList();
      final fileIdsInCollection = userPhotosInCollection.map((p) => p['fileId']).toList();

      print('  fileIds dans collection photos: $fileIdsInCollection');

      // Vérifier les correspondances
      for (var fileId in photoUrls) {
        final existsInCollection = fileIdsInCollection.contains(fileId);
        final icon = existsInCollection ? '✅' : '❌';
        print('    $icon $fileId ${existsInCollection ? "trouvé" : "MANQUANT dans collection photos"}');
      }

      print('');
    }
  }
}
