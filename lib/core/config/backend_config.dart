/// Configuration du backend
///
/// Pour basculer entre Appwrite Local et le backend local Node.js,
/// changez la valeur de USE_LOCAL_BACKEND

class BackendConfig {
  // 🔧 CONFIGURATION : Changez cette valeur pour basculer de backend
  static const bool USE_LOCAL_BACKEND = false; // true = Node.js local, false = Appwrite Local

  // ⚠️ IMPORTANT : Avant de passer à false (Appwrite), assurez-vous de :
  // 1. Avoir Appwrite installé et démarré (docker-compose up -d)
  // 2. Avoir créé un projet dans Appwrite console (http://localhost)
  // 3. Avoir mis à jour le projectId dans appwrite_service.dart
  // 4. Avoir créé la base de données et les collections
  // 5. Avoir créé le bucket de storage

  static String get backendName => USE_LOCAL_BACKEND ? 'Backend Local (Node.js)' : 'Appwrite Local';

  static String get backendUrl => USE_LOCAL_BACKEND
      ? 'http://localhost:3000'
      : 'http://localhost/v1';
}
