import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:image_picker/image_picker.dart';

/// Compression vidéo spécifique pour Web
/// Utilise le script JavaScript video_compressor.js
Future<Map<String, dynamic>> compressVideoWeb(XFile videoFile, double maxSizeMB) async {
  // Détecter le type MIME depuis l'extension si mimeType est null
  String mimeType = videoFile.mimeType ?? 'video/mp4';

  if (mimeType.isEmpty || mimeType == 'application/octet-stream') {
    // Détecter depuis l'extension
    final extension = videoFile.name.split('.').last.toLowerCase();
    mimeType = switch (extension) {
      'mp4' => 'video/mp4',
      'webm' => 'video/webm',
      'mov' => 'video/quicktime',
      'avi' => 'video/x-msvideo',
      'mkv' => 'video/x-matroska',
      _ => 'video/mp4', // Par défaut
    };
  }

  print('🎬 Compression Web - Type MIME: $mimeType, Nom: ${videoFile.name}');

  // Convertir XFile en File HTML
  final bytes = await videoFile.readAsBytes();
  final blob = html.Blob([bytes], mimeType);
  final file = html.File([blob], videoFile.name, {'type': mimeType});

  // Appeler la fonction JavaScript
  final compressFunction = js_util.getProperty(html.window, 'compressVideoFile');

  if (compressFunction == null) {
    throw Exception('Script de compression vidéo non chargé. Vérifiez que video_compressor.js est inclus dans index.html');
  }

  // Appeler la fonction et attendre le résultat
  final resultPromise = js_util.callMethod(compressFunction, 'call', [null, file, maxSizeMB]);
  final result = await js_util.promiseToFuture<dynamic>(resultPromise);

  // Extraire les données du résultat
  final bytesList = js_util.getProperty<List<dynamic>>(result, 'bytes');
  final fileName = js_util.getProperty<String>(result, 'fileName');
  final originalSize = js_util.getProperty<int>(result, 'originalSize');
  final compressedSize = js_util.getProperty<int>(result, 'compressedSize');

  return {
    'bytes': (bytesList as List).cast<int>(),
    'fileName': fileName as String,
    'originalSize': originalSize as int,
    'compressedSize': compressedSize as int,
  };
}
