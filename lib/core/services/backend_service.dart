/// Service universel qui route automatiquement vers Appwrite ou le backend local
/// selon la configuration

import 'package:appwrite/appwrite.dart' as appwrite;
import 'dart:typed_data';
import 'appwrite_service.dart';
import 'local_backend_service.dart';
import '../config/backend_config.dart';

class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  AppwriteService? _appwrite;
  LocalBackendService? _local;

  AppwriteService get appwrite {
    _appwrite ??= AppwriteService();
    return _appwrite!;
  }

  LocalBackendService get local {
    _local ??= LocalBackendService();
    return _local!;
  }

  Future<void> init() async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      local.init(); // localStorage est synchrone
    } else {
      appwrite.init();
    }
  }

  // === AUTHENTIFICATION ===

  Future<dynamic> getCurrentUser() async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.getCurrentUser();
    } else {
      return await appwrite.getCurrentUser();
    }
  }

  Future<dynamic> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.createAccount(email: email, password: password, name: name);
    } else {
      return await appwrite.createAccount(email: email, password: password, name: name);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      await local.createEmailPasswordSession(email: email, password: password);
    } else {
      await appwrite.login(email: email, password: password);
    }
  }

  Future<void> logout() async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      await local.logout();
    } else {
      await appwrite.logout();
    }
  }

  // === BASE DE DONNÉES ===

  Future<dynamic> getUserProfile(String userId) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.getDocument(
        databaseId: '',
        collectionId: 'users',
        documentId: userId,
      );
    } else {
      return await appwrite.getUserProfile(userId);
    }
  }

  Future<dynamic> createUserProfile({
    required String userId,
    required String name,
    required String email,
    required int age,
    required String gender,
    required String bio,
    required double latitude,
    required double longitude,
    List<String>? interests,
    List<String>? photoUrls,
    String? height,
    String? occupation,
    String? education,
    List<String>? lookingFor,
  }) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      print('🔵 BackendService.createUserProfile - DÉBUT');
      // Pour le backend local, le profil est créé automatiquement
      final data = {
        'name': name,
        'age': age,
        'gender': gender,
        'bio': bio,
        'latitude': latitude,
        'longitude': longitude,
      };

      // Ajouter les champs optionnels s'ils sont fournis
      if (interests != null) data['interests'] = interests;
      if (photoUrls != null) data['photoUrls'] = photoUrls;
      if (height != null) data['height'] = height;
      if (occupation != null) data['occupation'] = occupation;
      if (education != null) data['education'] = education;
      if (lookingFor != null) data['lookingFor'] = lookingFor;

      print('🔵 BackendService - Data: $data');
      print('🔵 BackendService - Appel updateDocument...');

      final result = await local.updateDocument(
        databaseId: '',
        collectionId: 'users',
        documentId: userId,
        data: data,
      );

      print('🔵 BackendService - Résultat: $result');
      return result;
    } else {
      return await appwrite.createUserProfile(
        userId: userId,
        name: name,
        email: email,
        age: age,
        gender: gender,
        bio: bio,
        latitude: latitude,
        longitude: longitude,
        interests: interests,
        photoUrls: photoUrls,
        height: height,
        occupation: occupation,
        education: education,
        lookingFor: lookingFor,
      );
    }
  }

  Future<dynamic> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.updateDocument(
        databaseId: '',
        collectionId: 'users',
        documentId: userId,
        data: data,
      );
    } else {
      return await appwrite.updateUserProfile(userId: userId, data: data);
    }
  }

  Future<dynamic> getUsers() async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.listDocuments(
        databaseId: '',
        collectionId: 'users',
      );
    } else {
      return await appwrite.getAllUsers();
    }
  }

  Future<dynamic> getVideos({int limit = 100}) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.listDocuments(
        databaseId: '',
        collectionId: 'videos',
      );
    } else {
      return await appwrite.getVideos(limit: limit);
    }
  }

  /// Récupérer les vidéos avec pagination (limit et offset)
  Future<dynamic> getVideosPaginated({required int limit, required int offset}) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.listDocuments(
        databaseId: '',
        collectionId: 'videos',
        limit: limit,
        offset: offset,
      );
    } else {
      return await appwrite.getVideosPaginated(limit: limit, offset: offset);
    }
  }

  Future<dynamic> getUserVideos(String userId) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      // Récupérer toutes les vidéos puis filtrer par userId côté client
      final allVideos = await local.listDocuments(
        databaseId: '',
        collectionId: 'videos',
      );

      // Filtrer pour ne garder que les vidéos de cet utilisateur
      final userVideos = (allVideos.documents as List)
          .where((doc) => doc.data['userId'] == userId)
          .toList();

      // Retourner un objet avec la structure attendue
      return _FilteredDocumentList(userVideos);
    } else {
      return await appwrite.getUserVideos(userId);
    }
  }

  Future<dynamic> getVideoById(String videoId) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.getDocument(
        databaseId: '',
        collectionId: 'videos',
        documentId: videoId,
      );
    } else {
      return await appwrite.getVideoById(videoId);
    }
  }

  Future<dynamic> likeUser({
    required String fromUserId,
    required String toUserId,
  }) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.likeUser(toUserId);
    } else {
      return await appwrite.likeUser(
        fromUserId: fromUserId,
        toUserId: toUserId,
      );
    }
  }

  Future<dynamic> getLikesSent() async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.getLikesSent();
    } else {
      return await appwrite.getLikesSent();
    }
  }

  Future<dynamic> getLikesReceived() async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.getLikesReceived();
    } else {
      return await appwrite.getLikesReceived();
    }
  }

  Future<dynamic> getLikedVideos() async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.getLikedVideos();
    } else {
      return await appwrite.getLikedVideos();
    }
  }

  Future<dynamic> likeVideo(String videoId) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.likeVideo(videoId);
    } else {
      return await appwrite.likeVideo(videoId);
    }
  }

  Future<dynamic> unlikeVideo(String videoId) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.unlikeVideo(videoId);
    } else {
      return await appwrite.unlikeVideo(videoId);
    }
  }

  Future<dynamic> getVideo(String videoId) async {
    // Pour l'instant uniquement Appwrite, local backend n'a pas cette méthode
    return await appwrite.getVideo(videoId);
  }

  Future<dynamic> incrementVideoView(String videoId) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.incrementVideoView(videoId);
    } else {
      return await appwrite.incrementVideoView(videoId);
    }
  }

  Future<dynamic> getMatches(String userId) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.getMatches();
    } else {
      return await appwrite.getMatches(userId);
    }
  }

  Future<bool> checkMatch(String userId) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.checkMatch(userId);
    } else {
      return await appwrite.checkMatch(userId);
    }
  }

  Future<int> getMatchesCount() async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.getMatchesCount();
    } else {
      return await appwrite.getMatchesCount();
    }
  }

  Future<dynamic> getNearbyUsers({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
  }) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      // Pour le backend local, on retourne tous les utilisateurs actifs
      return await local.listDocuments(
        databaseId: '',
        collectionId: 'users',
      );
    } else {
      return await appwrite.getNearbyUsers(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
    }
  }

  // === STOCKAGE ===

  Future<dynamic> uploadProfilePhoto({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      // Détecter le mimeType depuis l'extension
      String mimeType = 'image/jpeg'; // Par défaut
      final extension = fileName.toLowerCase().split('.').last;
      switch (extension) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
      }

      return await local.createFile(
        bucketId: '',
        fileId: fileName,
        bytes: fileBytes,
        filename: fileName,
        mimeType: mimeType,
      );
    } else {
      return await appwrite.uploadProfilePhoto(
        userId: userId,
        fileBytes: fileBytes,
        fileName: fileName,
      );
    }
  }

  Future<void> deleteProfilePhoto({
    required String userId,
    required String fileId,
  }) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      await local.deleteFile(
        bucketId: '',
        fileId: fileId,
      );
    } else {
      return await appwrite.deleteProfilePhoto(
        userId: userId,
        fileId: fileId,
      );
    }
  }

  Future<void> deleteVideo(String videoId) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.deleteVideo(videoId);
    } else {
      return await appwrite.deleteVideo(videoId);
    }
  }

  Future<dynamic> uploadVideo({
    required String userId,
    required String filePath,
    required String title,
    String? description,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      if (fileBytes == null) {
        throw Exception('fileBytes requis pour l\'upload avec le backend local');
      }
      if (fileName == null) {
        throw Exception('fileName requis pour l\'upload avec le backend local');
      }

      return await local.uploadVideo(
        userId: userId,
        fileBytes: Uint8List.fromList(fileBytes),
        fileName: fileName,
        title: title,
        description: description,
      );
    } else {
      return await appwrite.uploadVideo(
        userId: userId,
        filePath: filePath,
        title: title,
        description: description,
        fileBytes: fileBytes,
        fileName: fileName,
      );
    }
  }

  String getFileView(String fileId) {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return local.getFileView(bucketId: '', fileId: fileId);
    } else {
      return appwrite.getPhotoUrl(fileId);
    }
  }

  String getPhotoUrl(String fileId) {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return local.getFileView(bucketId: '', fileId: fileId);
    } else {
      return appwrite.getPhotoUrl(fileId);
    }
  }

  String getVideoUrl(String fileId) {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return local.getFileView(bucketId: '', fileId: fileId);
    } else {
      return appwrite.getVideoUrl(fileId);
    }
  }

  // === REPORTS & BLOCKING ===

  Future<dynamic> reportUser({
    required String reportedUserId,
    required String reportType,
    required String description,
  }) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.reportUser(
        reportedUserId: reportedUserId,
        reportType: reportType,
        description: description,
      );
    } else {
      return await appwrite.reportUser(
        reportedUserId: reportedUserId,
        reportType: reportType,
        description: description,
      );
    }
  }

  Future<dynamic> blockUser(String blockedUserId, {String? reason}) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.blockUser(blockedUserId, reason: reason);
    } else {
      return await appwrite.blockUser(blockedUserId, reason: reason);
    }
  }

  Future<void> unblockUser(String blockedUserId) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      await local.unblockUser(blockedUserId);
    } else {
      await appwrite.unblockUser(blockedUserId);
    }
  }

  Future<dynamic> getBlockedUsers() async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.getBlockedUsers();
    } else {
      return await appwrite.getBlockedUsers();
    }
  }

  Future<bool> isUserBlocked(String userId) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.isUserBlocked(userId);
    } else {
      return await appwrite.isUserBlocked(userId);
    }
  }

  // === CHAT ===

  Future<dynamic> sendMessage({
    required String matchId,
    required String receiverId,
    required String message,
    String? mediaUrl,
  }) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.sendMessage(
        matchId: matchId,
        receiverId: receiverId,
        message: message,
        mediaUrl: mediaUrl,
      );
    } else {
      return await appwrite.sendMessage(
        matchId: matchId,
        receiverId: receiverId,
        message: message,
        mediaUrl: mediaUrl,
      );
    }
  }

  Future<dynamic> getMessages({
    required String matchId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.getMessages(
        matchId: matchId,
        limit: limit,
        offset: offset,
      );
    } else {
      return await appwrite.getMessages(
        matchId: matchId,
        limit: limit,
        offset: offset,
      );
    }
  }

  Future<void> markMessagesAsRead(String matchId) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      await local.markMessagesAsRead(matchId);
    } else {
      await appwrite.markMessagesAsRead(matchId);
    }
  }

  Future<int> getUnreadMessagesCount() async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.getUnreadMessagesCount();
    } else {
      return await appwrite.getUnreadMessagesCount();
    }
  }

  dynamic subscribeToMessages({
    required String matchId,
    required Function(dynamic) onMessage,
  }) {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      // Local backend doesn't support realtime, return null
      return null;
    } else {
      return appwrite.subscribeToMessages(
        matchId: matchId,
        onMessage: onMessage,
      );
    }
  }

  // === TYPING INDICATOR ===

  Future<void> sendTypingIndicator({
    required String matchId,
    required String userId,
    required bool isTyping,
  }) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      await local.sendTypingIndicator(
        matchId: matchId,
        userId: userId,
        isTyping: isTyping,
      );
    } else {
      await appwrite.sendTypingIndicator(
        matchId: matchId,
        userId: userId,
        isTyping: isTyping,
      );
    }
  }

  dynamic subscribeToTypingIndicator({
    required String matchId,
    required Function(String userId, bool isTyping) onTypingChange,
  }) {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      // Local backend doesn't support realtime, return null
      return null;
    } else {
      return appwrite.subscribeToTypingIndicator(
        matchId: matchId,
        onTypingChange: onTypingChange,
      );
    }
  }
}

// Classe helper pour retourner une liste filtrée avec la bonne structure
class _FilteredDocumentList {
  final List<dynamic> documents;

  _FilteredDocumentList(this.documents);
}

  /// Rechercher des utilisateurs par géographie (continent, pays, ville)
  Future<dynamic> getUsersByGeography({
    List<String>? continents,
    List<String>? countries,
    List<String>? cities,
  }) async {
    if (BackendConfig.USE_LOCAL_BACKEND) {
      return await local.listDocuments(
        databaseId: '',
        collectionId: 'users',
      );
    } else {
      return await appwrite.getUsersByGeography(
        continents: continents,
        countries: countries,
        cities: cities,
      );
    }
  }
