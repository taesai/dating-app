/// Configuration Cloudinary pour la gestion des vidéos
class CloudinaryConfig {
  // Identifiants Cloudinary
  static const String cloudName = 'dpfwub9rb';
  static const String apiKey = '752743795153795';
  static const String apiSecret = 'AtMKJ7wbsBRho-XnJjv40XsOLKI';

  // Dossier de stockage des vidéos dans Cloudinary (dossier virtuel, pas local)
  static const String videoFolder = 'dating_app/videos';

  // Transformation par défaut pour les vidéos
  static const Map<String, dynamic> defaultVideoTransformation = {
    'quality': 'auto',
    'fetch_format': 'auto',
  };
}
