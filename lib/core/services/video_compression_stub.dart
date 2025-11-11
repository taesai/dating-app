import 'package:image_picker/image_picker.dart';

/// Stub pour les plateformes non-Web
/// Cette fonction ne sera jamais appelée sur mobile car le code vérifie kIsWeb
Future<Map<String, dynamic>> compressVideoWeb(XFile videoFile, double maxSizeMB) async {
  throw UnsupportedError('La compression Web n\'est disponible que sur la plateforme Web');
}
