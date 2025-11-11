import 'dart:io';
import 'dart:convert';
import 'migration_config.dart';

/// Script pour créer automatiquement toutes les collections dans Appwrite Cloud
void main() async {
  print('═══════════════════════════════════════════════════════');
  print('🚀 CRÉATION AUTOMATIQUE DES COLLECTIONS APPWRITE CLOUD');
  print('═══════════════════════════════════════════════════════');
  print('');
  print('Endpoint: ${MigrationConfig.cloudEndpoint}');
  print('Project: ${MigrationConfig.cloudProjectId}');
  print('Database: ${MigrationConfig.cloudDatabaseId}');
  print('');

  final creator = AppwriteCollectionCreator();

  try {
    // Créer toutes les collections
    await creator.createAllCollections();

    print('\n═══════════════════════════════════════════════════════');
    print('✅ TOUTES LES COLLECTIONS ONT ÉTÉ CRÉÉES !');
    print('═══════════════════════════════════════════════════════');
    print('\nProchaine étape:');
    print('  → Créez le bucket "medias" manuellement dans la Console');
    print('  → Ou lancez: dart run scripts/create_bucket.dart');

  } catch (e, stackTrace) {
    print('\n❌ ERREUR: $e');
    print('Stack trace: $stackTrace');
  }
}

class AppwriteCollectionCreator {
  final String endpoint = MigrationConfig.cloudEndpoint;
  final String projectId = MigrationConfig.cloudProjectId;
  final String apiKey = MigrationConfig.cloudApiKey;
  final String databaseId = MigrationConfig.cloudDatabaseId;

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
    } else if (method == 'GET') {
      request = await _httpClient.getUrl(uri);
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

  Future<void> createAllCollections() async {
    print('📦 Création des collections...\n');

    // 1. Users
    await createUsersCollection();

    // 2. Videos
    await createVideosCollection();

    // 3. Matches
    await createMatchesCollection();

    // 4. Chat Messages
    await createChatMessagesCollection();

    // 5. Video Likes
    await createVideoLikesCollection();

    // 6. Photos
    await createPhotosCollection();

    // 7. Reports
    await createReportsCollection();

    // 8. Blocked Users
    await createBlockedUsersCollection();

    // 9. Likes
    await createLikesCollection();
  }

  Future<String> createCollection(String collectionId, String name) async {
    print('📦 Création de la collection: $name...');

    try {
      final result = await _makeRequest('POST', '/databases/$databaseId/collections', {
        'collectionId': collectionId,
        'name': name,
        'documentSecurity': true,
        'enabled': true,
      });

      print('   ✅ Collection créée: ${result['\$id']}');
      return result['\$id'];
    } catch (e) {
      if (e.toString().contains('409')) {
        print('   ⚠️ Collection déjà existante, on continue...');
        return collectionId;
      }
      rethrow;
    }
  }

  Future<void> createStringAttribute(
    String collectionId,
    String key,
    int size, {
    bool required = false,
    bool array = false,
    String? defaultValue,
  }) async {
    try {
      await _makeRequest('POST', '/databases/$databaseId/collections/$collectionId/attributes/string', {
        'key': key,
        'size': size,
        'required': required,
        'array': array,
        if (defaultValue != null) 'default': defaultValue,
      });
      print('      ✅ $key (string)');
      await Future.delayed(Duration(milliseconds: 500)); // Éviter rate limiting
    } catch (e) {
      if (!e.toString().contains('409')) {
        print('      ❌ Erreur $key: $e');
      }
    }
  }

  Future<void> createIntegerAttribute(
    String collectionId,
    String key, {
    bool required = false,
    int? defaultValue,
  }) async {
    try {
      await _makeRequest('POST', '/databases/$databaseId/collections/$collectionId/attributes/integer', {
        'key': key,
        'required': required,
        if (defaultValue != null) 'default': defaultValue,
      });
      print('      ✅ $key (integer)');
      await Future.delayed(Duration(milliseconds: 500));
    } catch (e) {
      if (!e.toString().contains('409')) {
        print('      ❌ Erreur $key: $e');
      }
    }
  }

  Future<void> createBooleanAttribute(
    String collectionId,
    String key, {
    bool required = false,
    bool? defaultValue,
  }) async {
    try {
      await _makeRequest('POST', '/databases/$databaseId/collections/$collectionId/attributes/boolean', {
        'key': key,
        'required': required,
        if (defaultValue != null) 'default': defaultValue,
      });
      print('      ✅ $key (boolean)');
      await Future.delayed(Duration(milliseconds: 500));
    } catch (e) {
      if (!e.toString().contains('409')) {
        print('      ❌ Erreur $key: $e');
      }
    }
  }

  Future<void> createDoubleAttribute(
    String collectionId,
    String key, {
    bool required = false,
  }) async {
    try {
      await _makeRequest('POST', '/databases/$databaseId/collections/$collectionId/attributes/double', {
        'key': key,
        'required': required,
      });
      print('      ✅ $key (double)');
      await Future.delayed(Duration(milliseconds: 500));
    } catch (e) {
      if (!e.toString().contains('409')) {
        print('      ❌ Erreur $key: $e');
      }
    }
  }

  Future<void> createDateTimeAttribute(
    String collectionId,
    String key, {
    bool required = false,
  }) async {
    try {
      await _makeRequest('POST', '/databases/$databaseId/collections/$collectionId/attributes/datetime', {
        'key': key,
        'required': required,
      });
      print('      ✅ $key (datetime)');
      await Future.delayed(Duration(milliseconds: 500));
    } catch (e) {
      if (!e.toString().contains('409')) {
        print('      ❌ Erreur $key: $e');
      }
    }
  }

  Future<void> createEmailAttribute(
    String collectionId,
    String key, {
    bool required = false,
  }) async {
    try {
      await _makeRequest('POST', '/databases/$databaseId/collections/$collectionId/attributes/email', {
        'key': key,
        'required': required,
      });
      print('      ✅ $key (email)');
      await Future.delayed(Duration(milliseconds: 500));
    } catch (e) {
      if (!e.toString().contains('409')) {
        print('      ❌ Erreur $key: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════
  // COLLECTION 1: USERS
  // ═══════════════════════════════════════════════════════
  Future<void> createUsersCollection() async {
    final collectionId = await createCollection('users', 'users');
    print('   📝 Création des attributs...');

    await createEmailAttribute(collectionId, 'email', required: true);
    await createStringAttribute(collectionId, 'name', 255, required: true);
    await createIntegerAttribute(collectionId, 'age', required: true);
    await createStringAttribute(collectionId, 'gender', 50, required: true);
    await createStringAttribute(collectionId, 'bio', 1000);
    await createStringAttribute(collectionId, 'photoUrls', 255, array: true);
    await createDoubleAttribute(collectionId, 'latitude');
    await createDoubleAttribute(collectionId, 'longitude');
    await createStringAttribute(collectionId, 'lookingFor', 50, array: true);
    await createStringAttribute(collectionId, 'interests', 100, array: true);
    await createStringAttribute(collectionId, 'city', 100);
    await createStringAttribute(collectionId, 'sexualOrientation', 100);
    await createStringAttribute(collectionId, 'relationshipGoal', 100);
    await createStringAttribute(collectionId, 'education', 100);
    await createStringAttribute(collectionId, 'profession', 100);
    await createIntegerAttribute(collectionId, 'height');
    await createBooleanAttribute(collectionId, 'smoker', defaultValue: false);
    await createBooleanAttribute(collectionId, 'drinker', defaultValue: false);
    await createBooleanAttribute(collectionId, 'hasChildren', defaultValue: false);
    await createBooleanAttribute(collectionId, 'wantsChildren', defaultValue: false);
    await createStringAttribute(collectionId, 'languages', 50, array: true);
    await createBooleanAttribute(collectionId, 'isActive', defaultValue: true);
    await createDateTimeAttribute(collectionId, 'lastSeen');
    await createStringAttribute(collectionId, 'subscriptionPlan', 50, defaultValue: 'FREE');
    await createDateTimeAttribute(collectionId, 'subscriptionStartedAt');
    await createDateTimeAttribute(collectionId, 'subscriptionExpiresAt');
    await createIntegerAttribute(collectionId, 'dailySwipesUsed', defaultValue: 0);
    await createDateTimeAttribute(collectionId, 'lastSwipeResetDate');

    print('   ✅ Collection users terminée\n');
  }

  // ═══════════════════════════════════════════════════════
  // COLLECTION 2: VIDEOS
  // ═══════════════════════════════════════════════════════
  Future<void> createVideosCollection() async {
    final collectionId = await createCollection('videos', 'videos');
    print('   📝 Création des attributs...');

    await createStringAttribute(collectionId, 'userId', 255, required: true);
    await createStringAttribute(collectionId, 'fileId', 255, required: true);
    await createStringAttribute(collectionId, 'title', 500, required: true);
    await createStringAttribute(collectionId, 'thumbnailUrl', 500);
    await createIntegerAttribute(collectionId, 'likes', defaultValue: 0);
    await createIntegerAttribute(collectionId, 'views', defaultValue: 0);
    await createDateTimeAttribute(collectionId, 'createdAt', required: true);
    await createBooleanAttribute(collectionId, 'isApproved', defaultValue: true);

    print('   ✅ Collection videos terminée\n');
  }

  // ═══════════════════════════════════════════════════════
  // COLLECTION 3: MATCHES
  // ═══════════════════════════════════════════════════════
  Future<void> createMatchesCollection() async {
    final collectionId = await createCollection('matches', 'matches');
    print('   📝 Création des attributs...');

    await createStringAttribute(collectionId, 'user1Id', 255, required: true);
    await createStringAttribute(collectionId, 'user2Id', 255, required: true);
    await createDateTimeAttribute(collectionId, 'createdAt', required: true);
    await createStringAttribute(collectionId, 'lastMessage', 1000);
    await createStringAttribute(collectionId, 'lastMessageSenderId', 255);
    await createDateTimeAttribute(collectionId, 'lastMessageDate');
    await createIntegerAttribute(collectionId, 'unreadCountUser1', defaultValue: 0);
    await createIntegerAttribute(collectionId, 'unreadCountUser2', defaultValue: 0);

    print('   ✅ Collection matches terminée\n');
  }

  // ═══════════════════════════════════════════════════════
  // COLLECTION 4: CHAT_MESSAGES
  // ═══════════════════════════════════════════════════════
  Future<void> createChatMessagesCollection() async {
    final collectionId = await createCollection('chat_messages', 'chat_messages');
    print('   📝 Création des attributs...');

    await createStringAttribute(collectionId, 'matchId', 255, required: true);
    await createStringAttribute(collectionId, 'senderId', 255, required: true);
    await createStringAttribute(collectionId, 'message', 5000, required: true);
    await createDateTimeAttribute(collectionId, 'timestamp', required: true);
    await createBooleanAttribute(collectionId, 'isRead', defaultValue: false);

    print('   ✅ Collection chat_messages terminée\n');
  }

  // ═══════════════════════════════════════════════════════
  // COLLECTION 5: VIDEO_LIKES
  // ═══════════════════════════════════════════════════════
  Future<void> createVideoLikesCollection() async {
    final collectionId = await createCollection('videoLikes', 'videoLikes');
    print('   📝 Création des attributs...');

    await createStringAttribute(collectionId, 'userId', 255, required: true);
    await createStringAttribute(collectionId, 'videoId', 255, required: true);
    await createDateTimeAttribute(collectionId, 'createdAt', required: true);

    print('   ✅ Collection videoLikes terminée\n');
  }

  // ═══════════════════════════════════════════════════════
  // COLLECTION 6: PHOTOS
  // ═══════════════════════════════════════════════════════
  Future<void> createPhotosCollection() async {
    final collectionId = await createCollection('photos', 'photos');
    print('   📝 Création des attributs...');

    await createStringAttribute(collectionId, 'userID', 255, required: true);
    await createStringAttribute(collectionId, 'fileId', 255, required: true);
    await createDateTimeAttribute(collectionId, 'createdAt', required: true);
    await createBooleanAttribute(collectionId, 'isApproved', defaultValue: false);
    await createBooleanAttribute(collectionId, 'isPhotoProfile', defaultValue: false);
    await createIntegerAttribute(collectionId, 'displayOrder', defaultValue: 0);

    print('   ✅ Collection photos terminée\n');
  }

  // ═══════════════════════════════════════════════════════
  // COLLECTION 7: REPORTS
  // ═══════════════════════════════════════════════════════
  Future<void> createReportsCollection() async {
    final collectionId = await createCollection('reports', 'reports');
    print('   📝 Création des attributs...');

    await createStringAttribute(collectionId, 'reporterId', 255, required: true);
    await createStringAttribute(collectionId, 'reportedUserId', 255, required: true);
    await createStringAttribute(collectionId, 'reason', 500, required: true);
    await createStringAttribute(collectionId, 'description', 2000);
    await createStringAttribute(collectionId, 'status', 50, defaultValue: 'pending');
    await createDateTimeAttribute(collectionId, 'createdAt', required: true);

    print('   ✅ Collection reports terminée\n');
  }

  // ═══════════════════════════════════════════════════════
  // COLLECTION 8: BLOCKED_USERS
  // ═══════════════════════════════════════════════════════
  Future<void> createBlockedUsersCollection() async {
    final collectionId = await createCollection('blockedUsers', 'blockedUsers');
    print('   📝 Création des attributs...');

    await createStringAttribute(collectionId, 'blockerId', 255, required: true);
    await createStringAttribute(collectionId, 'blockedUserId', 255, required: true);
    await createDateTimeAttribute(collectionId, 'createdAt', required: true);

    print('   ✅ Collection blockedUsers terminée\n');
  }

  // ═══════════════════════════════════════════════════════
  // COLLECTION 9: LIKES
  // ═══════════════════════════════════════════════════════
  Future<void> createLikesCollection() async {
    final collectionId = await createCollection('likes', 'likes');
    print('   📝 Création des attributs...');

    await createStringAttribute(collectionId, 'userId', 255, required: true);
    await createStringAttribute(collectionId, 'likedUserId', 255, required: true);
    await createDateTimeAttribute(collectionId, 'createdAt', required: true);

    print('   ✅ Collection likes terminée\n');
  }
}
