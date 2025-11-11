import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

/// Service de compression pour images et vidéos (compatible Web)
/// Réduit la taille des fichiers avant upload vers Appwrite
class CompressionService {
  static const int _imageQuality = 70; // Qualité JPEG (0-100)
  static const int _imageMaxWidth = 1920; // Largeur max en pixels
  static const int _imageMaxHeight = 1920; // Hauteur max en pixels

  static const int _thumbnailMaxWidth = 400; // Pour thumbnails
  static const int _thumbnailMaxHeight = 400;
  static const int _thumbnailQuality = 60;

  /// Compresser une image à partir de bytes
  /// Compatible Web et Mobile
  ///
  /// [imageBytes] - Bytes de l'image à compresser
  /// [quality] - Qualité de compression (0-100), par défaut 70
  /// [maxWidth] - Largeur maximale en pixels
  /// [maxHeight] - Hauteur maximale en pixels
  ///
  /// Retourne les bytes compressés ou null en cas d'erreur
  static Future<Uint8List?> compressImage({
    required Uint8List imageBytes,
    int quality = _imageQuality,
    int maxWidth = _imageMaxWidth,
    int maxHeight = _imageMaxHeight,
    String? fileName,
  }) async {
    try {
      print('📸 Compression image ${fileName ?? ""}');
      final originalSize = imageBytes.length;
      print('📊 Taille originale: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');

      if (kIsWeb) {
        // Compression Web avec Canvas
        return await _compressImageWeb(
          imageBytes,
          quality: quality,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );
      } else {
        // Pour mobile/desktop (à implémenter plus tard si nécessaire)
        print('⚠️ Compression mobile non implémentée, retour image originale');
        return imageBytes;
      }
    } catch (e) {
      print('❌ Erreur compression image: $e');
      return null;
    }
  }

  /// Compression d'image spécifique au Web
  static Future<Uint8List?> _compressImageWeb(
    Uint8List imageBytes, {
    required int quality,
    required int maxWidth,
    required int maxHeight,
  }) async {
    try {
      // Créer un blob depuis les bytes
      final blob = html.Blob([imageBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Créer une image HTML
      final img = html.ImageElement();
      img.src = url;

      // Attendre que l'image soit chargée
      await img.onLoad.first;

      // Calculer les nouvelles dimensions en gardant le ratio
      int targetWidth = img.naturalWidth!;
      int targetHeight = img.naturalHeight!;

      if (targetWidth > maxWidth || targetHeight > maxHeight) {
        final ratio = targetWidth / targetHeight;
        if (targetWidth > targetHeight) {
          targetWidth = maxWidth;
          targetHeight = (maxWidth / ratio).round();
        } else {
          targetHeight = maxHeight;
          targetWidth = (maxHeight * ratio).round();
        }
      }

      print('📐 Dimensions: ${img.naturalWidth}x${img.naturalHeight} → ${targetWidth}x${targetHeight}');

      // Créer un canvas pour redimensionner
      final canvas = html.CanvasElement(width: targetWidth, height: targetHeight);
      final ctx = canvas.context2D;

      // Dessiner l'image redimensionnée
      ctx.drawImageScaled(img, 0, 0, targetWidth, targetHeight);

      // Convertir en JPEG avec qualité spécifiée
      final dataUrl = canvas.toDataUrl('image/jpeg', quality / 100);

      // Nettoyer
      html.Url.revokeObjectUrl(url);

      // Convertir data URL en bytes
      final base64Data = dataUrl.split(',')[1];
      final bytes = base64Decode(base64Data);

      final compressedSize = bytes.length;
      final ratio = (1 - (compressedSize / imageBytes.length)) * 100;
      print('✅ Taille compressée: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
      print('📉 Réduction: ${ratio.toStringAsFixed(1)}%');

      return bytes;
    } catch (e) {
      print('❌ Erreur compression Web: $e');
      return null;
    }
  }

  /// Décoder base64 en bytes
  static Uint8List base64Decode(String base64String) {
    final trimmed = base64String.trim();
    final normalized = trimmed.replaceAll('-', '+').replaceAll('_', '/');

    // Ajouter padding si nécessaire
    final padding = normalized.length % 4;
    final padded = padding > 0
        ? normalized + ('=' * (4 - padding))
        : normalized;

    final List<int> bytes = [];
    for (int i = 0; i < padded.length; i += 4) {
      final chunk = padded.substring(i, i + 4);
      final decoded = _decodeBase64Chunk(chunk);
      bytes.addAll(decoded);
    }

    return Uint8List.fromList(bytes);
  }

  static List<int> _decodeBase64Chunk(String chunk) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    int val = 0;
    int bits = 0;
    final List<int> bytes = [];

    for (int i = 0; i < chunk.length; i++) {
      final c = chunk[i];
      if (c == '=') break;

      final index = chars.indexOf(c);
      if (index == -1) continue;

      val = (val << 6) | index;
      bits += 6;

      if (bits >= 8) {
        bits -= 8;
        bytes.add((val >> bits) & 0xFF);
      }
    }

    return bytes;
  }

  /// Créer une miniature d'image
  static Future<Uint8List?> createImageThumbnail({
    required Uint8List imageBytes,
    int quality = _thumbnailQuality,
    int maxWidth = _thumbnailMaxWidth,
    int maxHeight = _thumbnailMaxHeight,
    String? fileName,
  }) async {
    return compressImage(
      imageBytes: imageBytes,
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      fileName: fileName,
    );
  }

  /// Compresser une vidéo Web
  /// Note: Sur Web, la compression vidéo côté client est limitée
  /// On peut seulement valider la taille et suggérer à l'utilisateur
  static Future<Map<String, dynamic>> analyzeVideo({
    required html.File videoFile,
  }) async {
    try {
      print('🎬 Analyse vidéo: ${videoFile.name}');
      final size = videoFile.size;
      print('📊 Taille: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');

      // Créer un élément vidéo pour obtenir les métadonnées
      final video = html.VideoElement();
      final url = html.Url.createObjectUrlFromBlob(videoFile);
      video.src = url;

      // Attendre les métadonnées
      await video.onLoadedMetadata.first;

      final duration = video.duration;
      final width = video.videoWidth;
      final height = video.videoHeight;

      // Nettoyer
      html.Url.revokeObjectUrl(url);

      print('🎥 Durée: ${duration.toStringAsFixed(1)}s');
      print('📐 Résolution: ${width}x${height}');

      // Calculer si la vidéo est trop lourde
      final maxSizeBytes = 50 * 1024 * 1024; // 50 MB max recommandé
      final isTooBig = size > maxSizeBytes;

      return {
        'size': size,
        'duration': duration,
        'width': width,
        'height': height,
        'sizeMB': (size / 1024 / 1024).toStringAsFixed(2),
        'isTooBig': isTooBig,
        'maxSizeMB': (maxSizeBytes / 1024 / 1024).toStringAsFixed(0),
        'canCompress': false, // Compression vidéo Web pas supportée côté client
        'recommendation': isTooBig
            ? 'Vidéo trop volumineuse. Veuillez utiliser une vidéo plus courte ou de moindre qualité.'
            : 'Taille acceptable pour upload.',
      };
    } catch (e) {
      print('❌ Erreur analyse vidéo: $e');
      return {'error': e.toString()};
    }
  }

  /// Générer une miniature depuis une vidéo Web
  static Future<Uint8List?> generateVideoThumbnail({
    required html.File videoFile,
    int quality = 60,
    double timePosition = 1.0, // Seconde à capturer
  }) async {
    try {
      print('🖼️ Génération thumbnail vidéo: ${videoFile.name}');

      // Créer un élément vidéo
      final video = html.VideoElement();
      final url = html.Url.createObjectUrlFromBlob(videoFile);
      video.src = url;

      // Attendre que la vidéo soit prête
      await video.onLoadedMetadata.first;

      // Se positionner à la frame souhaitée
      video.currentTime = timePosition;
      await video.onSeeked.first;

      // Créer un canvas aux dimensions de la vidéo
      final canvas = html.CanvasElement(
        width: video.videoWidth,
        height: video.videoHeight,
      );
      final ctx = canvas.context2D;

      // Capturer la frame actuelle
      ctx.drawImageScaled(video, 0, 0, video.videoWidth, video.videoHeight);

      // Convertir en JPEG
      final dataUrl = canvas.toDataUrl('image/jpeg', quality / 100);

      // Nettoyer
      html.Url.revokeObjectUrl(url);

      // Convertir en bytes
      final base64Data = dataUrl.split(',')[1];
      final bytes = base64Decode(base64Data);

      print('✅ Thumbnail généré: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
      return bytes;
    } catch (e) {
      print('❌ Erreur génération thumbnail: $e');
      return null;
    }
  }

  /// Estimer la taille après compression
  static Map<String, dynamic> estimateCompression({
    required int originalSize,
    required String fileType, // 'image' ou 'video'
  }) {
    double estimatedRatio;

    if (fileType == 'image') {
      // Images: généralement 50-70% de réduction
      estimatedRatio = 0.4; // Garde 40% de la taille
    } else {
      // Vidéos: sur Web, pas de compression, garde 100%
      estimatedRatio = 1.0;
    }

    final estimatedSize = (originalSize * estimatedRatio).toInt();
    final savings = originalSize - estimatedSize;
    final savingsPercent = ((savings / originalSize) * 100).toStringAsFixed(1);

    return {
      'originalSize': originalSize,
      'estimatedSize': estimatedSize,
      'savings': savings,
      'savingsPercent': savingsPercent,
      'originalSizeMB': (originalSize / 1024 / 1024).toStringAsFixed(2),
      'estimatedSizeMB': (estimatedSize / 1024 / 1024).toStringAsFixed(2),
    };
  }

  /// Valider la taille d'un fichier
  static bool validateFileSize({
    required int fileSize,
    required String fileType,
  }) {
    const maxImageSize = 10 * 1024 * 1024; // 10 MB pour images
    const maxVideoSize = 50 * 1024 * 1024; // 50 MB pour vidéos

    if (fileType == 'image') {
      return fileSize <= maxImageSize;
    } else {
      return fileSize <= maxVideoSize;
    }
  }
}
