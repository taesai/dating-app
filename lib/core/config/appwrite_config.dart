/// Configuration Appwrite - Basculement LOCAL / CLOUD
class AppwriteConfig {
  // ═══════════════════════════════════════════════════════
  // ⚠️ CHANGEZ ICI POUR BASCULER ENTRE LOCAL ET CLOUD
  // ═══════════════════════════════════════════════════════
  static const bool USE_CLOUD = true; // true = Cloud, false = Local

  // ═══════════════════════════════════════════════════════
  // APPWRITE LOCAL
  // ═══════════════════════════════════════════════════════
  static const String localEndpoint = 'http://localhost/v1';
  static const String localProjectId = '68e7d31c0038917ac217';
  static const String localDatabaseId = '68e8a9320008c0036625';

  // ═══════════════════════════════════════════════════════
  // APPWRITE CLOUD
  // ═══════════════════════════════════════════════════════
  static const String cloudEndpoint = 'https://cloud.appwrite.io/v1';
  static const String cloudProjectId = '681829e4003b243e6681';
  static const String cloudDatabaseId = '68db88f700374422bfc7';

  // ═══════════════════════════════════════════════════════
  // CONFIGURATION ACTIVE (calculée automatiquement)
  // ═══════════════════════════════════════════════════════
  static String get endpoint => USE_CLOUD ? cloudEndpoint : localEndpoint;
  static String get projectId => USE_CLOUD ? cloudProjectId : localProjectId;
  static String get databaseId => USE_CLOUD ? cloudDatabaseId : localDatabaseId;

  // ═══════════════════════════════════════════════════════
  // COLLECTIONS IDs (identiques local et cloud)
  // ═══════════════════════════════════════════════════════
  static const String usersCollectionId = 'users';
  static const String videosCollectionId = 'videos';
  static const String likesCollectionId = 'likes';
  static const String matchesCollectionId = 'matches';
  static const String videoLikesCollectionId = 'videoLikes';
  static const String reportsCollectionId = 'reports';
  static const String blockedUsersCollectionId = 'blockedUsers';
  static const String chatMessagesCollectionId = 'chat_messages';
  static const String photosCollectionId = 'photos';

  // ═══════════════════════════════════════════════════════
  // STORAGE BUCKETS
  // ═══════════════════════════════════════════════════════
  static const String localMediasBucketId = 'medias';
  static const String cloudMediasBucketId = '69097fa900347fbdd407';

  static String get mediasBucketId => USE_CLOUD ? cloudMediasBucketId : localMediasBucketId;

  // ═══════════════════════════════════════════════════════
  // HELPER: Afficher la config active
  // ═══════════════════════════════════════════════════════
  static void printActiveConfig() {
    print('═══════════════════════════════════════════════════════');
    print('📡 CONFIGURATION APPWRITE ACTIVE');
    print('═══════════════════════════════════════════════════════');
    print('Mode: ${USE_CLOUD ? "☁️ CLOUD" : "🏠 LOCAL"}');
    print('Endpoint: $endpoint');
    print('Project: $projectId');
    print('Database: $databaseId');
    print('═══════════════════════════════════════════════════════');
  }
}
