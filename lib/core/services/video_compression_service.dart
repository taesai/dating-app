import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

// Import conditionnel pour Web
import 'video_compression_web.dart' if (dart.library.io) 'video_compression_stub.dart';

/// Service de compression vidéo optimisé
/// Pour Web: utilise JavaScript + Canvas + MediaRecorder pour compression réelle
/// Pour mobile: peut utiliser des bibliothèques natives
class VideoCompressionService {
  /// Compresse une vidéo pour atteindre ~2 MB max
  ///
  /// Paramètres de compression Web:
  /// - Résolution max: 720p (pour 2 MB)
  /// - Bitrate vidéo: calculé dynamiquement selon durée
  /// - Codec: VP8/VP9 (WebM)
  /// - Audio: Opus 64kbps
  Future<CompressedVideo> compressVideo({
    required XFile videoFile,
    double maxSizeMB = 2.0,
    VideoQuality quality = VideoQuality.high,
  }) async {
    try {
      print('🎬 Début compression vidéo: ${videoFile.name}');

      final originalBytes = await videoFile.readAsBytes();
      final originalSize = originalBytes.lengthInBytes;
      print('📦 Taille originale: ${_formatBytes(originalSize)}');

      if (kIsWeb) {
        // Utiliser la compression JavaScript sur Web
        print('🌐 Compression Web avec MediaRecorder...');
        final result = await compressVideoWeb(videoFile, maxSizeMB);

        return CompressedVideo(
          bytes: Uint8List.fromList(result['bytes'] as List<int>),
          fileName: result['fileName'] as String,
          originalSize: result['originalSize'] as int,
          compressedSize: result['compressedSize'] as int,
          compressionRatio: (result['compressedSize'] as int) / (result['originalSize'] as int),
          wasCompressed: true,
        );
      } else {
        // Sur mobile, retour de la vidéo originale pour l'instant
        print('📱 Platform mobile - compression native à implémenter');

        return CompressedVideo(
          bytes: originalBytes,
          fileName: videoFile.name,
          originalSize: originalSize,
          compressedSize: originalSize,
          compressionRatio: 1.0,
          wasCompressed: false,
        );
      }
    } catch (e) {
      print('❌ Erreur compression vidéo: $e');
      rethrow;
    }
  }

  /// Vérifie si une vidéo nécessite une compression
  Future<bool> needsCompression(XFile videoFile, {double maxSizeMB = 2.0}) async {
    final bytes = await videoFile.readAsBytes();
    final sizeInMB = bytes.lengthInBytes / (1024 * 1024);
    return sizeInMB > maxSizeMB;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// Qualité de compression vidéo
enum VideoQuality {
  low,       // Petite taille, qualité acceptable
  medium,    // Bon compromis
  high,      // Bonne qualité, taille raisonnable (recommandé)
  veryHigh,  // Très bonne qualité, moins de compression
}

/// Résultat de compression vidéo
class CompressedVideo {
  final Uint8List bytes;
  final String fileName;
  final int originalSize;
  final int compressedSize;
  final double compressionRatio;
  final bool wasCompressed;

  CompressedVideo({
    required this.bytes,
    required this.fileName,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionRatio,
    required this.wasCompressed,
  });

  /// Économie d'espace en pourcentage
  double get spaceSavings => (1 - compressionRatio) * 100;

  /// Taille compressée formatée
  String get compressedSizeFormatted => _formatBytes(compressedSize);

  /// Taille originale formatée
  String get originalSizeFormatted => _formatBytes(originalSize);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  String toString() {
    if (!wasCompressed) {
      return 'Vidéo non compressée: $originalSizeFormatted';
    }
    return 'Compression: $originalSizeFormatted → $compressedSizeFormatted (${spaceSavings.toStringAsFixed(1)}% d\'économie)';
  }
}
