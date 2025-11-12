import 'dart:typed_data';
import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_flutter/image/cld_image.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:cloudinary_url_gen/transformation/video_edit/video_edit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../config/cloudinary_config.dart';

/// Service de gestion des vidéos via Cloudinary CDN
class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  late Cloudinary _cloudinary;
  bool _initialized = false;

  /// Initialise Cloudinary avec les credentials
  void initialize() {
    if (_initialized) return;

    _cloudinary = Cloudinary.fromStringUrl(
      'cloudinary://${CloudinaryConfig.apiKey}:${CloudinaryConfig.apiSecret}@${CloudinaryConfig.cloudName}',
    );

    CloudinaryContext.cloudinary = _cloudinary;
    _initialized = true;

    print('✅ Cloudinary initialisé: ${CloudinaryConfig.cloudName}');
  }

  /// Upload une vidéo vers Cloudinary
  /// Retourne l'URL publique de la vidéo uploadée
  Future<String> uploadVideo({
    required Uint8List videoBytes,
    required String fileName,
    String? userId,
  }) async {
    if (!_initialized) initialize();

    try {
      print('📤 Upload vidéo: $fileName (${videoBytes.length} bytes)');

      // Préparer le public_id (nom unique dans Cloudinary)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = userId != null
          ? '${CloudinaryConfig.videoFolder}/${userId}_$timestamp'
          : '${CloudinaryConfig.videoFolder}/$timestamp';

      // Créer la requête multipart
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/video/upload',
      );

      final request = http.MultipartRequest('POST', url);

      // Ajouter les paramètres
      request.fields['api_key'] = CloudinaryConfig.apiKey;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['folder'] = CloudinaryConfig.videoFolder;
      request.fields['public_id'] = publicId;

      // Générer la signature (DOIT inclure folder et public_id)
      final signature = _generateSignature(
        publicId: publicId,
        timestamp: timestamp,
        folder: CloudinaryConfig.videoFolder,
      );
      request.fields['signature'] = signature;

      // Ajouter le fichier vidéo
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          videoBytes,
          filename: fileName,
        ),
      );

      // Envoyer la requête
      print('⏳ Upload en cours...');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final secureUrl = data['secure_url'] as String;
        print('✅ Vidéo uploadée: $secureUrl');
        return secureUrl;
      } else {
        print('❌ Erreur upload: ${response.statusCode}');
        print('Response: $responseBody');
        throw Exception('Échec upload Cloudinary: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur uploadVideo: $e');
      rethrow;
    }
  }

  /// Génère l'URL de streaming optimisée pour une vidéo
  String getVideoUrl(String publicId, {Map<String, dynamic>? transformation}) {
    if (!_initialized) initialize();

    final baseUrl = 'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/video/upload';

    if (transformation != null && transformation.isNotEmpty) {
      final transformParams = transformation.entries
          .map((e) => '${e.key}_${e.value}')
          .join(',');
      return '$baseUrl/$transformParams/$publicId';
    }

    return '$baseUrl/$publicId';
  }

  /// Extrait le public_id depuis une URL Cloudinary
  String? extractPublicId(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Format: /video/upload/v1234567890/folder/publicId.mp4
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= pathSegments.length - 1) {
        return null;
      }

      // Prendre tous les segments après 'upload' et la version
      final segments = pathSegments.sublist(uploadIndex + 2);
      final publicId = segments.join('/');

      // Retirer l'extension si présente
      return publicId.replaceAll(RegExp(r'\.[^.]+$'), '');
    } catch (e) {
      print('❌ Erreur extractPublicId: $e');
      return null;
    }
  }

  /// Supprime une vidéo de Cloudinary
  Future<bool> deleteVideo(String publicId) async {
    if (!_initialized) initialize();

    try {
      print('🗑️ Suppression vidéo: $publicId');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final signature = _generateSignature(
        publicId: publicId,
        timestamp: timestamp,
      );

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/video/destroy',
      );

      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'api_key': CloudinaryConfig.apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Vidéo supprimée: ${data['result']}');
        return data['result'] == 'ok';
      } else {
        print('❌ Erreur suppression: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur deleteVideo: $e');
      return false;
    }
  }

  /// Génère une signature SHA-1 pour l'API Cloudinary
  String _generateSignature({
    String? publicId,
    required int timestamp,
    String? folder,
  }) {
    // Créer la chaîne à signer avec les paramètres triés alphabétiquement
    final params = <String>[];

    if (folder != null && folder.isNotEmpty) {
      params.add('folder=$folder');
    }

    if (publicId != null && publicId.isNotEmpty) {
      params.add('public_id=$publicId');
    }

    params.add('timestamp=$timestamp');

    // Trier les paramètres et créer la chaîne
    params.sort();
    final stringToSign = params.join('&') + CloudinaryConfig.apiSecret;

    // Générer le hash SHA-1
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }

  /// Vérifie si une URL est une URL Cloudinary
  bool isCloudinaryUrl(String url) {
    return url.contains('cloudinary.com') && url.contains(CloudinaryConfig.cloudName);
  }

  /// Obtient une URL de thumbnail pour une vidéo
  String getVideoThumbnail(String publicId, {int? time}) {
    if (!_initialized) initialize();

    final timeParam = time != null ? 'so_${time}s' : 'so_0s';
    return 'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/video/upload/$timeParam,f_jpg,q_auto/$publicId.jpg';
  }
}
