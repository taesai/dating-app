import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'dart:developer' as developer;
import 'dart:html' as html; // Pour localStorage sur web

class LocalBackendService {
  static final LocalBackendService _instance = LocalBackendService._internal();
  factory LocalBackendService() => _instance;
  LocalBackendService._internal();

  // Configuration
  static const String baseUrl = 'http://localhost:3000/api';
  static const String _tokenKey = 'local_backend_token';
  String? _token;

  void init() {
    developer.log('🔧 Initialisation Local Backend Service', name: 'LocalBackend');
    developer.log('📍 Base URL: $baseUrl', name: 'LocalBackend');

    // Charger le token sauvegardé
    _loadToken();

    developer.log('✅ Local Backend Service initialisé', name: 'LocalBackend');
  }

  void _loadToken() {
    try {
      // Utiliser localStorage pour Web
      _token = html.window.localStorage[_tokenKey];
      if (_token != null && _token!.isNotEmpty) {
        developer.log('🔑 Token chargé depuis localStorage', name: 'LocalBackend');
      }
    } catch (e) {
      developer.log('⚠️ Erreur chargement token: $e', name: 'LocalBackend');
    }
  }

  void _saveToken(String token) {
    try {
      // Utiliser localStorage pour Web
      html.window.localStorage[_tokenKey] = token;
      _token = token;
      developer.log('💾 Token sauvegardé dans localStorage', name: 'LocalBackend');
    } catch (e) {
      developer.log('⚠️ Erreur sauvegarde token: $e', name: 'LocalBackend');
    }
  }

  void _clearToken() {
    try {
      // Utiliser localStorage pour Web
      html.window.localStorage.remove(_tokenKey);
      _token = null;
      developer.log('🗑️ Token supprimé de localStorage', name: 'LocalBackend');
    } catch (e) {
      developer.log('⚠️ Erreur suppression token: $e', name: 'LocalBackend');
    }
  }

  // Headers avec authentification
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // === AUTHENTIFICATION ===

  Future<dynamic> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'age': 25, // Valeur par défaut, sera mise à jour après
          'gender': 'other',
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _saveToken(data['token']); // Sauvegarder le token
        return data['user'];
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur createAccount: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<dynamic> createEmailPasswordSession({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _saveToken(data['token']); // Sauvegarder le token
        return data['user'];
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur login: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<dynamic> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Token invalide ou expiré, le supprimer
        developer.log('🔒 Token invalide, suppression', name: 'LocalBackend');
        _clearToken();
        throw Exception('Non authentifié');
      } else {
        throw Exception('Non authentifié');
      }
    } catch (e) {
      developer.log('❌ Erreur getCurrentUser: $e', name: 'LocalBackend');
      // Si erreur de connexion au serveur, supprimer aussi le token
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        _clearToken();
      }
      rethrow;
    }
  }

  Future<void> deleteSession({required String sessionId}) async {
    await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: _headers,
    );
    _token = null;
  }

  Future<void> logout() async {
    await deleteSession(sessionId: 'current');
    _clearToken(); // Supprimer le token sauvegardé
  }

  // === BASE DE DONNÉES ===

  Future<dynamic> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      String endpoint;
      Map<String, dynamic> payload = {...data, 'id': documentId};

      // Router vers le bon endpoint selon la collection
      if (collectionId == 'users') {
        endpoint = '$baseUrl/users/profile';
      } else if (collectionId == 'videos') {
        endpoint = '$baseUrl/videos';
      } else if (collectionId == 'likes') {
        endpoint = '$baseUrl/likes/${data['targetUserId']}';
      } else if (collectionId == 'matches') {
        endpoint = '$baseUrl/matches';
      } else {
        throw Exception('Collection non supportée: $collectionId');
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _MockDocument(jsonDecode(response.body));
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur createDocument: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<dynamic> getDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
  }) async {
    try {
      String endpoint;

      if (collectionId == 'users') {
        endpoint = '$baseUrl/users/$documentId';
      } else {
        throw Exception('Collection non supportée: $collectionId');
      }

      final response = await http.get(
        Uri.parse(endpoint),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return _MockDocument(jsonDecode(response.body));
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur getDocument: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<dynamic> listDocuments({
    required String databaseId,
    required String collectionId,
    List<String>? queries,
    int? limit,
    int? offset,
  }) async {
    try {
      String endpoint;

      if (collectionId == 'users') {
        endpoint = '$baseUrl/users';
      } else if (collectionId == 'videos') {
        endpoint = '$baseUrl/videos';
      } else if (collectionId == 'matches') {
        endpoint = '$baseUrl/matches';
      } else {
        endpoint = '$baseUrl/$collectionId';
      }

      // Ajouter les paramètres de pagination si fournis
      final uri = Uri.parse(endpoint);
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final finalUri = queryParams.isEmpty
          ? uri
          : uri.replace(queryParameters: queryParams);

      final response = await http.get(
        finalUri,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var documents = data['documents'] ?? [];

        // Appliquer limit et offset côté client si le backend ne les gère pas
        if (offset != null && offset > 0) {
          documents = documents.skip(offset).toList();
        }
        if (limit != null && limit > 0) {
          documents = documents.take(limit).toList();
        }

        return _MockDocumentList(documents);
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur listDocuments: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<dynamic> updateDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      String endpoint;

      if (collectionId == 'users') {
        endpoint = '$baseUrl/users/me';
      } else {
        throw Exception('Collection non supportée: $collectionId');
      }

      developer.log('📤 PATCH $endpoint', name: 'LocalBackend');
      developer.log('📦 Data: ${jsonEncode(data)}', name: 'LocalBackend');

      final response = await http.patch(
        Uri.parse(endpoint),
        headers: _headers,
        body: jsonEncode(data),
      );

      developer.log('📸 Response Status: ${response.statusCode}', name: 'LocalBackend');
      developer.log('📸 Response Body: ${response.body}', name: 'LocalBackend');

      if (response.statusCode == 200) {
        return _MockDocument(jsonDecode(response.body));
      } else {
        final errorMsg = response.statusCode == 404
          ? 'Endpoint non trouvé: $endpoint'
          : jsonDecode(response.body)['error'] ?? 'Erreur ${response.statusCode}';
        throw Exception(errorMsg);
      }
    } catch (e) {
      developer.log('❌ Erreur updateDocument: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  // === STOCKAGE ===

  Future<dynamic> createFile({
    required String bucketId,
    required String fileId,
    required Uint8List bytes,
    String? filename,
    String? mimeType,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/photos'),
      );

      request.headers.addAll(_headers);
      request.files.add(http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: filename ?? 'photo.jpg',
        contentType: http_parser.MediaType.parse(mimeType ?? 'image/jpeg'),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      developer.log('📸 Upload response - Status: ${response.statusCode}', name: 'LocalBackend');
      developer.log('📸 Upload response - Body: ${response.body}', name: 'LocalBackend');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('📸 Upload data parsed: $data', name: 'LocalBackend');
        developer.log('📸 FileId: ${data['fileId']}, PhotoUrl: ${data['photoUrl']}', name: 'LocalBackend');
        return _MockFile(data['fileId'], data['photoUrl']);
      } else {
        developer.log('❌ Upload failed - Status: ${response.statusCode}', name: 'LocalBackend');
        developer.log('❌ Upload failed - Body: ${response.body}', name: 'LocalBackend');
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur createFile: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  String getFileView({
    required String bucketId,
    required String fileId,
  }) {
    // Le fileId contient déjà le chemin complet pour le backend local
    if (fileId.startsWith('/uploads/')) {
      return 'http://localhost:3000$fileId';
    }
    return 'http://localhost:3000/uploads/photos/$fileId';
  }

  Future<void> deleteFile({
    required String bucketId,
    required String fileId,
  }) async {
    try {
      developer.log('🗑️ Suppression du fichier: $fileId', name: 'LocalBackend');

      final response = await http.delete(
        Uri.parse('$baseUrl/users/photos/$fileId'),
        headers: _headers,
      );

      developer.log('🗑️ Delete response - Status: ${response.statusCode}', name: 'LocalBackend');

      if (response.statusCode != 200) {
        developer.log('❌ Delete failed - Body: ${response.body}', name: 'LocalBackend');
        throw Exception(jsonDecode(response.body)['error']);
      }

      developer.log('✅ Fichier supprimé avec succès', name: 'LocalBackend');
    } catch (e) {
      developer.log('❌ Erreur deleteFile: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  String getFilePreview({
    required String bucketId,
    required String fileId,
    int? width,
    int? height,
  }) {
    return getFileView(bucketId: bucketId, fileId: fileId);
  }

  // Upload de vidéo
  Future<dynamic> uploadVideo({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
    String? title,
    String? description,
  }) async {
    try {
      developer.log('🎬 Upload vidéo - Début', name: 'LocalBackend');
      developer.log('  Taille: ${fileBytes.length} bytes', name: 'LocalBackend');
      developer.log('  Nom: $fileName', name: 'LocalBackend');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/videos/upload'),
      );

      request.headers.addAll(_headers);

      // Ajouter la vidéo
      request.files.add(http.MultipartFile.fromBytes(
        'video',
        fileBytes,
        filename: fileName,
        contentType: http_parser.MediaType.parse('video/mp4'),
      ));

      // Ajouter les champs
      if (title != null) request.fields['title'] = title;
      if (description != null) request.fields['description'] = description;

      developer.log('📤 Envoi de la requête...', name: 'LocalBackend');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      developer.log('📸 Upload response - Status: ${response.statusCode}', name: 'LocalBackend');
      developer.log('📸 Upload response - Body: ${response.body}', name: 'LocalBackend');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        developer.log('✅ Vidéo uploadée: ${data['videoId']}', name: 'LocalBackend');
        return {
          'videoId': data['videoId'],
          'fileId': data['fileId'],
          'videoUrl': data['videoUrl'],
        };
      } else {
        developer.log('❌ Upload failed - Status: ${response.statusCode}', name: 'LocalBackend');
        developer.log('❌ Upload failed - Body: ${response.body}', name: 'LocalBackend');
        throw Exception(jsonDecode(response.body)['error'] ?? 'Erreur upload vidéo');
      }
    } catch (e) {
      developer.log('❌ Erreur uploadVideo: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  // Supprimer une vidéo
  Future<void> deleteVideo(String videoId) async {
    try {
      developer.log('🗑️ Suppression de la vidéo: $videoId', name: 'LocalBackend');

      final response = await http.delete(
        Uri.parse('$baseUrl/videos/$videoId'),
        headers: _headers,
      );

      developer.log('🗑️ Delete response - Status: ${response.statusCode}', name: 'LocalBackend');

      if (response.statusCode != 200) {
        developer.log('❌ Delete failed - Body: ${response.body}', name: 'LocalBackend');
        throw Exception(jsonDecode(response.body)['error'] ?? 'Erreur suppression vidéo');
      }

      developer.log('✅ Vidéo supprimée avec succès', name: 'LocalBackend');
    } catch (e) {
      developer.log('❌ Erreur deleteVideo: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  // === LIKES ===

  Future<dynamic> likeUser(String targetUserId) async {
    try {
      developer.log('❤️ Like user: $targetUserId', name: 'LocalBackend');

      final response = await http.post(
        Uri.parse('$baseUrl/likes/$targetUserId'),
        headers: _headers,
      );

      developer.log('Response: ${response.statusCode} - ${response.body}', name: 'LocalBackend');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'isMatch': data['isMatch'] ?? false,
          'like': data['like'],
        };
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Erreur like');
      }
    } catch (e) {
      developer.log('❌ Erreur likeUser: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<dynamic> getLikesSent() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/likes/sent'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _MockDocumentList(data['likes'] ?? []);
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur getLikesSent: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<dynamic> getLikesReceived() async {
    try {
      developer.log('📊 GET /video-likes/received', name: 'LocalBackend');
      final response = await http.get(
        Uri.parse('$baseUrl/video-likes/received'),
        headers: _headers,
      );

      developer.log('Response status: ${response.statusCode}', name: 'LocalBackend');
      developer.log('Response body: ${response.body}', name: 'LocalBackend');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final documents = data['documents'] ?? [];
        developer.log('✅ Likes vidéos reçus: ${documents.length}', name: 'LocalBackend');
        return _MockDocumentList(documents);
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur getLikesReceived: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<dynamic> likeVideo(String videoId) async {
    try {
      developer.log('❤️ Like vidéo: $videoId', name: 'LocalBackend');

      final response = await http.post(
        Uri.parse('$baseUrl/video-likes/$videoId'),
        headers: _headers,
      );

      developer.log('Response: ${response.statusCode} - ${response.body}', name: 'LocalBackend');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'likeId': data['likeId'],
          'totalLikes': data['totalLikes'],
        };
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Erreur like vidéo');
      }
    } catch (e) {
      developer.log('❌ Erreur likeVideo: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  // Retirer le like d'une vidéo
  Future<dynamic> unlikeVideo(String videoId) async {
    try {
      developer.log('💔 Unlike vidéo: $videoId', name: 'LocalBackend');

      final response = await http.delete(
        Uri.parse('$baseUrl/video-likes/$videoId'),
        headers: _headers,
      );

      developer.log('Response: ${response.statusCode} - ${response.body}', name: 'LocalBackend');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'totalLikes': data['totalLikes'] ?? 0,
        };
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Erreur unlike vidéo');
      }
    } catch (e) {
      developer.log('❌ Erreur unlikeVideo: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  // Récupérer les vidéos likées par l'utilisateur connecté
  Future<dynamic> getLikedVideos() async {
    try {
      developer.log('📊 GET /video-likes/given', name: 'LocalBackend');
      final response = await http.get(
        Uri.parse('$baseUrl/video-likes/given'),
        headers: _headers,
      );

      developer.log('Response status: ${response.statusCode}', name: 'LocalBackend');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final documents = data['likes'] ?? data['documents'] ?? [];
        developer.log('✅ Vidéos likées: ${documents.length}', name: 'LocalBackend');
        return {'documents': documents};
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur getLikedVideos: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  // Incrémenter le compteur de vues d'une vidéo
  Future<dynamic> incrementVideoView(String videoId) async {
    try {
      developer.log('👁️ Incrémentation vue pour vidéo: $videoId', name: 'LocalBackend');

      final response = await http.post(
        Uri.parse('$baseUrl/videos/$videoId/view'),
        headers: _headers,
      );

      developer.log('Response: ${response.statusCode} - ${response.body}', name: 'LocalBackend');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'videoId': videoId,
          'totalViews': data['totalViews'] ?? data['views'],
        };
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Erreur incrémentation vue');
      }
    } catch (e) {
      developer.log('❌ Erreur incrementVideoView: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  // === MATCHES ===

  Future<dynamic> getMatches() async {
    try {
      developer.log('📊 GET /matches', name: 'LocalBackend');
      final response = await http.get(
        Uri.parse('$baseUrl/matches'),
        headers: _headers,
      );

      developer.log('Response status: ${response.statusCode}', name: 'LocalBackend');
      developer.log('Response body: ${response.body}', name: 'LocalBackend');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final documents = data['matches'] ?? data['documents'] ?? [];
        developer.log('✅ Matches: ${documents.length}', name: 'LocalBackend');
        return _MockDocumentList(documents);
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur getMatches: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<bool> checkMatch(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/matches/check/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isMatch'] ?? false;
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur checkMatch: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<int> getMatchesCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/matches/count'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur getMatchesCount: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  // === REPORTS & BLOCKING ===

  Future<dynamic> reportUser({
    required String reportedUserId,
    required String reportType,
    required String description,
  }) async {
    try {
      developer.log('🚨 POST /reports', name: 'LocalBackend');
      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: _headers,
        body: jsonEncode({
          'reportedUserId': reportedUserId,
          'reportType': reportType,
          'description': description,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return _MockDocument(data['report'] ?? data);
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur reportUser: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<dynamic> blockUser(String blockedUserId, {String? reason}) async {
    try {
      developer.log('🚫 POST /blocks', name: 'LocalBackend');
      final response = await http.post(
        Uri.parse('$baseUrl/blocks'),
        headers: _headers,
        body: jsonEncode({
          'blockedUserId': blockedUserId,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return _MockDocument(data['block'] ?? data);
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur blockUser: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<void> unblockUser(String blockedUserId) async {
    try {
      developer.log('✅ DELETE /blocks/$blockedUserId', name: 'LocalBackend');
      final response = await http.delete(
        Uri.parse('$baseUrl/blocks/$blockedUserId'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur unblockUser: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<dynamic> getBlockedUsers() async {
    try {
      developer.log('📊 GET /blocks', name: 'LocalBackend');
      final response = await http.get(
        Uri.parse('$baseUrl/blocks'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final documents = data['blocks'] ?? data['documents'] ?? [];
        return _MockDocumentList(documents);
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur getBlockedUsers: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<bool> isUserBlocked(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/blocks/check/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isBlocked'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      developer.log('❌ Erreur isUserBlocked: $e', name: 'LocalBackend');
      return false;
    }
  }

  // === CHAT ===

  Future<dynamic> sendMessage({
    required String matchId,
    required String receiverId,
    required String message,
    String? mediaUrl,
  }) async {
    try {
      developer.log('💬 POST /messages', name: 'LocalBackend');
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: _headers,
        body: jsonEncode({
          'matchId': matchId,
          'receiverId': receiverId,
          'message': message,
          'mediaUrl': mediaUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return _MockDocument(data['message'] ?? data);
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur sendMessage: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<dynamic> getMessages({
    required String matchId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      developer.log('📊 GET /messages/$matchId', name: 'LocalBackend');
      final response = await http.get(
        Uri.parse('$baseUrl/messages/$matchId?limit=$limit&offset=$offset'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final documents = data['messages'] ?? data['documents'] ?? [];
        return _MockDocumentList(documents);
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur getMessages: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String matchId) async {
    try {
      developer.log('✅ PUT /messages/$matchId/read', name: 'LocalBackend');
      final response = await http.put(
        Uri.parse('$baseUrl/messages/$matchId/read'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      developer.log('❌ Erreur markMessagesAsRead: $e', name: 'LocalBackend');
      rethrow;
    }
  }

  Future<int> getUnreadMessagesCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/unread/count'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      developer.log('❌ Erreur getUnreadMessagesCount: $e', name: 'LocalBackend');
      return 0;
    }
  }
}

// Classes mock pour compatibilité avec Appwrite
class _MockDocument {
  final Map<String, dynamic> data;

  _MockDocument(this.data);

  String get $id => data['\$id'] ?? data['id'] ?? '';
}

class _MockDocumentList {
  final List<dynamic> documents;

  _MockDocumentList(List<dynamic> docs)
      : documents = docs.map((d) => _MockDocument(d is Map<String, dynamic> ? d : {})).toList();
}

class _MockFile {
  final String $id;
  final String url;

  _MockFile(this.$id, this.url);
}

extension LocalBackendTypingIndicator on LocalBackendService {
  // Typing indicator - stocké temporairement dans localStorage
  Future<void> sendTypingIndicator({
    required String matchId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      final key = 'typing_$matchId';
      if (isTyping) {
        final data = {
          'userId': userId,
          'timestamp': DateTime.now().toIso8601String(),
        };
        html.window.localStorage[key] = jsonEncode(data);
      } else {
        html.window.localStorage.remove(key);
      }
    } catch (e) {
      developer.log('⚠️ Erreur sendTypingIndicator: $e', name: 'LocalBackend');
    }
  }
}
