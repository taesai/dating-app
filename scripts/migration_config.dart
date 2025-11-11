/// Configuration pour la migration Appwrite Local → Cloud
class MigrationConfig {
  // ═══════════════════════════════════════════════════════
  // APPWRITE LOCAL (pour exporter les données)
  // ═══════════════════════════════════════════════════════
  static const String localEndpoint = 'http://localhost/v1';
  static const String localProjectId = '68e7d31c0038917ac217';
  static const String localApiKey = 'standard_a0cbffeac40b2ea4b50b8170e31e6bb5547dc6b551200db1ad87019afdad0a0d9f3402799c676baae24eff4b261d93e76c68aabe0a802f693439dc00744bc6ad637a8c565c38e8165c9c968c9d9c07391aa7628ed643c1f7bbe2ae38fb332d7b6daced5250a058bc2fb4629e00946f3d9a23f9270e35fb44e1d209a84910c5e0';

  static const String localDatabaseId = '68e8a9320008c0036625';

  // ═══════════════════════════════════════════════════════
  // APPWRITE CLOUD (pour importer les données)
  // ═══════════════════════════════════════════════════════
  static const String cloudEndpoint = 'https://cloud.appwrite.io/v1';
  static const String cloudProjectId = '681829e4003b243e6681';
  static const String cloudApiKey = 'standard_230aa0ed7ca818de4bc298a6cfd85cc87cd8e5857cb24b9b33e72bef7cb641f0ef9380419a039d5838e6d05558e46285b41f092984545d8677629ddc663399836b285be55959435bf606c3f3357a6745a055f889bb1619b222e37911d24c6e67fb7d65b6a60654f88d0a56357bdb07b99ba18cfe51bf340388d0b21ec6cd9124';

  // Database ID dans Appwrite Cloud
  static const String cloudDatabaseId = '68db88f700374422bfc7'; // dating_app_db

  // Bucket ID dans Appwrite Cloud
  static const String cloudBucketId = '69097fa900347fbdd407'; // medias

  // ═══════════════════════════════════════════════════════
  // COLLECTIONS & BUCKETS IDs
  // ═══════════════════════════════════════════════════════
  static const Map<String, String> collections = {
    'users': '68e8a94100036164036c',
    'videos': '68e8a9590033c7be4dc4',
    'likes': '68e8a964001f4e07b9ee',
    'matches': '68e8a96e0037016de109',
    'videoLikes': '68e8a981000c5aa58027',
    'reports': '68f0a56b00369c620d1e',
    'blockedUsers': '68f0a7440035499ad376',
    'chatMessages': '68f0a82f002a6e6724ec',
    'photos': '68f1e01b00269bcaca0c',
  };

  static const Map<String, String> buckets = {
    'medias': '68e8a98e00106c06e748',
  };
}
