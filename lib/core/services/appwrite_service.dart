import 'package:appwrite/appwrite.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'appwrite_reports_service.dart';
import 'appwrite_chat_service.dart';
import '../config/appwrite_config.dart';

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;
  AppwriteService._internal();

  late Client client;
  late Account account;
  late Databases databases;
  late Storage storage;
  late Realtime realtime;

  // Services spécialisés
  late AppwriteReportsService reportsService;
  late AppwriteChatService chatService;

  // Configuration - UTILISE AppwriteConfig (LOCAL ou CLOUD)
  static String get endpoint => AppwriteConfig.endpoint;
  static String get projectId => AppwriteConfig.projectId;

  // Database & Collections IDs
  static String get databaseId => AppwriteConfig.databaseId;
  static String get usersCollectionId => AppwriteConfig.usersCollectionId;
  static String get videosCollectionId => AppwriteConfig.videosCollectionId;
  static String get likesCollectionId => AppwriteConfig.likesCollectionId;
  static String get matchesCollectionId => AppwriteConfig.matchesCollectionId;
  static String get videoLikesCollectionId => AppwriteConfig.videoLikesCollectionId;
  static String get reportsCollectionId => AppwriteConfig.reportsCollectionId;
  static String get blockedUsersCollectionId => AppwriteConfig.blockedUsersCollectionId;
  static String get chatMessagesCollectionId => AppwriteConfig.chatMessagesCollectionId;
  static String get photosCollectionId => AppwriteConfig.photosCollectionId;

  // Storage Buckets
  static String get mediasBucketId => AppwriteConfig.mediasBucketId;

  void init() {
    // Afficher la configuration active
    AppwriteConfig.printActiveConfig();

    developer.log('🔧 Initialisation Appwrite Service', name: 'AppwriteService');
    developer.log('📍 Endpoint: $endpoint', name: 'AppwriteService');
    developer.log('📁 Project ID: $projectId', name: 'AppwriteService');
    developer.log('💾 Database ID: $databaseId', name: 'AppwriteService');

    client = Client()
      ..setEndpoint(endpoint)
      ..setProject(projectId)
      ..setSelfSigned(status: true); // Pour dev uniquement

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    realtime = Realtime(client);

    // Initialiser les services spécialisés
    reportsService = AppwriteReportsService(
      databases: databases,
      account: account,
      databaseId: databaseId,
      reportsCollectionId: reportsCollectionId,
      blockedUsersCollectionId: blockedUsersCollectionId,
    );

    chatService = AppwriteChatService(
      databases: databases,
      account: account,
      realtime: realtime,
      databaseId: databaseId,
      chatMessagesCollectionId: chatMessagesCollectionId,
      matchesCollectionId: matchesCollectionId,
    );

    developer.log('✅ Appwrite Service initialisé', name: 'AppwriteService');
  }

  // Méthode de vérification de la connexion et de la configuration
  Future<Map<String, dynamic>> checkConnection() async {
    final results = <String, dynamic>{
      'endpoint': endpoint,
      'projectId': projectId,
      'databaseId': databaseId,
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <String, dynamic>{},
    };

    developer.log('🔍 Vérification de la connexion Appwrite...', name: 'AppwriteService');

    // Test 1: Vérifier le compte (si connecté)
    try {
      developer.log('Test 1: Vérification du compte utilisateur', name: 'AppwriteService');
      final user = await account.get();
      results['tests']['account'] = {
        'success': true,
        'userId': user.$id,
        'email': user.email,
        'message': 'Utilisateur connecté'
      };
      developer.log('✅ Compte OK: ${user.email}', name: 'AppwriteService');
    } catch (e) {
      developer.log('⚠️  Pas de compte connecté: $e', name: 'AppwriteService');
      results['tests']['account'] = {
        'success': false,
        'error': e.toString(),
        'message': 'Aucun utilisateur connecté (normal si pas encore de login)'
      };
    }

    // Test 2: Vérifier la base de données
    try {
      developer.log('Test 2: Accès à la base de données', name: 'AppwriteService');
      developer.log('📊 Tentative d\'accès à la database: $databaseId', name: 'AppwriteService');

      // Tester l'accès à la collection users
      final usersTest = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        queries: [Query.limit(1)],
      );

      results['tests']['usersCollection'] = {
        'success': true,
        'collectionId': usersCollectionId,
        'documentCount': usersTest.total,
        'message': 'Collection users accessible'
      };
      developer.log('✅ Collection users OK (${usersTest.total} documents)', name: 'AppwriteService');
    } catch (e) {
      developer.log('❌ Collection users Error: $e', name: 'AppwriteService', error: e);
      results['tests']['usersCollection'] = {
        'success': false,
        'collectionId': usersCollectionId,
        'error': e.toString(),
        'message': 'Collection users non accessible - Vérifiez qu\'elle existe dans Appwrite Console'
      };
    }

    // Test 3: Vérifier la collection videos
    try {
      developer.log('Test 3: Accès à la collection videos', name: 'AppwriteService');
      final videosTest = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        queries: [Query.limit(1)],
      );

      results['tests']['videosCollection'] = {
        'success': true,
        'collectionId': videosCollectionId,
        'documentCount': videosTest.total,
        'message': 'Collection videos accessible'
      };
      developer.log('✅ Collection videos OK (${videosTest.total} documents)', name: 'AppwriteService');
    } catch (e) {
      developer.log('❌ Collection videos Error: $e', name: 'AppwriteService', error: e);
      results['tests']['videosCollection'] = {
        'success': false,
        'collectionId': videosCollectionId,
        'error': e.toString(),
        'message': 'Collection videos non accessible'
      };
    }

    // Test 4: Vérifier la collection matches
    try {
      developer.log('Test 4: Accès à la collection matches', name: 'AppwriteService');
      final matchesTest = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: matchesCollectionId,
        queries: [Query.limit(1)],
      );

      results['tests']['matchesCollection'] = {
        'success': true,
        'collectionId': matchesCollectionId,
        'documentCount': matchesTest.total,
        'message': 'Collection matches accessible'
      };
      developer.log('✅ Collection matches OK (${matchesTest.total} documents)', name: 'AppwriteService');
    } catch (e) {
      developer.log('❌ Collection matches Error: $e', name: 'AppwriteService', error: e);
      results['tests']['matchesCollection'] = {
        'success': false,
        'collectionId': matchesCollectionId,
        'error': e.toString(),
        'message': 'Collection matches non accessible'
      };
    }

    // Test 5: Vérifier la collection likes
    try {
      developer.log('Test 5: Accès à la collection likes', name: 'AppwriteService');
      final likesTest = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: likesCollectionId,
        queries: [Query.limit(1)],
      );

      results['tests']['likesCollection'] = {
        'success': true,
        'collectionId': likesCollectionId,
        'documentCount': likesTest.total,
        'message': 'Collection likes accessible'
      };
      developer.log('✅ Collection likes OK (${likesTest.total} documents)', name: 'AppwriteService');
    } catch (e) {
      developer.log('❌ Collection likes Error: $e', name: 'AppwriteService', error: e);
      results['tests']['likesCollection'] = {
        'success': false,
        'collectionId': likesCollectionId,
        'error': e.toString(),
        'message': 'Collection likes non accessible'
      };
    }

    // Test 6: Vérifier le bucket de storage
    try {
      developer.log('Test 6: Accès au bucket de storage', name: 'AppwriteService');
      final filesTest = await storage.listFiles(
        bucketId: mediasBucketId,
        queries: [Query.limit(1)],
      );

      results['tests']['storageBucket'] = {
        'success': true,
        'bucketId': mediasBucketId,
        'fileCount': filesTest.total,
        'message': 'Bucket storage accessible'
      };
      developer.log('✅ Bucket storage OK (${filesTest.total} fichiers)', name: 'AppwriteService');
    } catch (e) {
      developer.log('❌ Bucket storage Error: $e', name: 'AppwriteService', error: e);
      results['tests']['storageBucket'] = {
        'success': false,
        'bucketId': mediasBucketId,
        'error': e.toString(),
        'message': 'Bucket storage non accessible'
      };
    }

    developer.log('🏁 Vérification terminée', name: 'AppwriteService');
    return results;
  }

  // Authentication
  Future<dynamic> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      return await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> login({
    required String email,
    required String password,
  }) async {
    try {
      return await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getCurrentUser() async {
    try {
      // Récupérer l'utilisateur authentifié
      final user = await account.get();

      // Essayer de récupérer son profil dans la collection users
      try {
        final profile = await databases.getDocument(
          databaseId: databaseId,
          collectionId: usersCollectionId,
          documentId: user.$id,
        );
        return profile;
      } catch (e) {
        // Si le profil n'existe pas, retourner juste l'objet User
        // L'app pourra alors proposer de créer le profil
        developer.log('⚠️ Profil non trouvé dans users collection pour ${user.$id}', name: 'AppwriteService');
        return user;
      }
    } catch (e) {
      rethrow;
    }
  }

  // User Profile
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
    try {
      return await databases.createDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
        data: {
          'name': name,
          'email': email,
          'age': age,
          'gender': gender,
          'bio': bio,
          'latitude': latitude,
          'longitude': longitude,
          'interests': interests ?? [],
          'photoUrls': photoUrls ?? [],
          'videoIds': [],
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
          'isProfileApproved': false, // Approbation manuelle par admin
          'subscriptionPlan': 'free',
          'height': height,
          'occupation': occupation,
          'education': education,
          'lookingFor': lookingFor ?? [],
          'verified': false,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getUserProfile(String userId) async {
    try {
      return await databases.getDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateUserProfile({
    required String userId,
    Map<String, dynamic>? data,
  }) async {
    try {
      return await databases.updateDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
        data: data!,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Videos
  Future<dynamic> uploadVideo({
    required String userId,
    required String filePath,
    required String title,
    String? description,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      developer.log('📹 Upload vidéo démarré...', name: 'AppwriteService');
      developer.log('User ID: $userId', name: 'AppwriteService');
      developer.log('File path: $filePath', name: 'AppwriteService');
      developer.log('File name: $fileName', name: 'AppwriteService');

      // Upload video file
      final InputFile inputFile;
      if (fileBytes != null && fileName != null) {
        // Pour le web, utiliser les bytes
        developer.log('📱 Upload depuis bytes (WEB)', name: 'AppwriteService');
        inputFile = InputFile.fromBytes(
          bytes: fileBytes,
          filename: fileName,
        );
      } else {
        // Pour mobile, utiliser le path
        developer.log('📱 Upload depuis path (MOBILE)', name: 'AppwriteService');
        inputFile = InputFile.fromPath(path: filePath);
      }

      final fileId = ID.unique();
      final file = await storage.createFile(
        bucketId: mediasBucketId,
        fileId: fileId,
        file: inputFile,
      );

      developer.log('✅ Fichier uploadé: $fileId', name: 'AppwriteService');

      // Create video document
      final videoDoc = await databases.createDocument(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'fileId': fileId,
          'title': title,
          'description': description ?? '',
          'views': 0,
          'likes': 0,
          'createdAt': DateTime.now().toIso8601String(),
          'isApproved': false, // Nécessite approbation admin
        },
      );

      developer.log('📹 Document vidéo créé: ${videoDoc.$id}', name: 'AppwriteService');

      // Mettre à jour le profil utilisateur avec l'ID de la vidéo
      try {
        final userProfile = await getUserProfile(userId);
        final currentVideoIds = List<String>.from(userProfile.data['videoIds'] ?? []);
        currentVideoIds.add(videoDoc.$id);

        await updateUserProfile(
          userId: userId,
          data: {'videoIds': currentVideoIds},
        );

        developer.log('✅ Profil mis à jour avec videoId: ${videoDoc.$id}', name: 'AppwriteService');
      } catch (e) {
        developer.log('⚠️ Erreur mise à jour profil: $e', name: 'AppwriteService');
        // Continue même si la mise à jour échoue
      }

      return videoDoc;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getVideos({int limit = 5, String? lastVideoId}) async {
    try {
      final queries = [
        Query.equal('isApproved', true), // FILTRE: Seulement les vidéos approuvées
        Query.limit(limit),
        Query.orderDesc('createdAt'),
      ];

      if (lastVideoId != null) {
        queries.add(Query.cursorAfter(lastVideoId));
      }

      return await databases.listDocuments(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        queries: queries,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer les vidéos avec pagination par offset
  Future<dynamic> getVideosPaginated({required int limit, required int offset}) async {
    try {
      return await databases.listDocuments(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        queries: [
          Query.equal('isApproved', true), // FILTRE: Seulement les vidéos approuvées
          Query.limit(limit),
          Query.offset(offset),
          Query.orderDesc('createdAt'),
        ],
      );
    } catch (e) {
      print('❌ Erreur getVideosPaginated: $e');
      rethrow;
    }
  }

  /// Récupérer TOUTES les vidéos (pour admin - sans filtre isApproved)
  Future<dynamic> getAllVideosForAdmin({int limit = 100}) async {
    try {
      return await databases.listDocuments(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        queries: [
          Query.limit(limit),
          Query.orderDesc('createdAt'),
        ],
      );
    } catch (e) {
      developer.log('❌ Erreur getAllVideosForAdmin: $e', name: 'AppwriteService');
      rethrow;
    }
  }

  Future<dynamic> getVideoById(String videoId) async {
    try {
      return await databases.getDocument(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        documentId: videoId,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteVideo(String videoId) async {
    try {
      developer.log('🗑️ Suppression vidéo: $videoId', name: 'AppwriteService');

      // Récupérer le document vidéo pour obtenir le fileId
      final videoDoc = await getVideoById(videoId);
      final fileId = videoDoc.data['fileId'];

      // Supprimer le fichier du storage
      if (fileId != null) {
        await storage.deleteFile(
          bucketId: mediasBucketId,
          fileId: fileId,
        );
        developer.log('✅ Fichier vidéo supprimé: $fileId', name: 'AppwriteService');
      }

      // Supprimer le document vidéo
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        documentId: videoId,
      );

      developer.log('✅ Document vidéo supprimé: $videoId', name: 'AppwriteService');
    } catch (e) {
      developer.log('❌ Erreur deleteVideo: $e', name: 'AppwriteService');
      rethrow;
    }
  }

  Future<dynamic> getUserVideos(String userId) async {
    try {
      return await databases.listDocuments(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('createdAt'),
        ],
      );
    } catch (e) {
      rethrow;
    }
  }

  String getVideoUrl(String fileId) {
    return '$endpoint/storage/buckets/$mediasBucketId/files/$fileId/view?project=$projectId';
  }

  String getPhotoUrl(String fileId) {
    return '$endpoint/storage/buckets/$mediasBucketId/files/$fileId/view?project=$projectId';
  }

  // Likes & Matches
  Future<dynamic> likeUser({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      // Create like
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: likesCollectionId,
        documentId: ID.unique(),
        data: {
          'fromUserId': fromUserId,
          'toUserId': toUserId,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      // Check if it's a match (mutual like)
      final reciprocalLike = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: likesCollectionId,
        queries: [
          Query.equal('fromUserId', toUserId),
          Query.equal('toUserId', fromUserId),
        ],
      );

      if (reciprocalLike.documents.isNotEmpty) {
        // Create match
        return await databases.createDocument(
          databaseId: databaseId,
          collectionId: matchesCollectionId,
          documentId: ID.unique(),
          data: {
            'user1Id': fromUserId,
            'user2Id': toUserId,
            'createdAt': DateTime.now().toIso8601String(),
            'isActive': true,
          },
        );
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getMatches(String userId) async {
    try {
      return await databases.listDocuments(
        databaseId: databaseId,
        collectionId: matchesCollectionId,
        queries: [
          Query.or([
            Query.equal('user1Id', userId),
            Query.equal('user2Id', userId),
          ]),
          Query.equal('isActive', true),
          Query.orderDesc('createdAt'),
        ],
      );
    } catch (e) {
      rethrow;
    }
  }

  // Nearby Users (pour la carte)
  Future<dynamic> getNearbyUsers({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
  }) async {
    try {
      // Note: Pour une vraie implémentation de géolocalisation,
      // vous devriez utiliser une fonction côté serveur avec géohashing
      // Ici on récupère tous les utilisateurs actifs
      return await databases.listDocuments(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        queries: [
          Query.equal('isActive', true),
          Query.limit(100),
        ],
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get all users (pour l'admin)
  Future<dynamic> getAllUsers() async {
    try {
      return await databases.listDocuments(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        queries: [
          Query.limit(500), // Limite haute pour admin
        ],
      );
    } catch (e) {
      rethrow;
    }
  }

  // Upload profile photo
  Future<String> uploadProfilePhoto({
    required String userId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      developer.log('📸 Upload photo de profil démarré...', name: 'AppwriteService');
      developer.log('User ID: $userId', name: 'AppwriteService');
      developer.log('File name: $fileName', name: 'AppwriteService');

      // Déterminer le type MIME en fonction de l'extension
      String? contentType;
      final extension = fileName.toLowerCase().split('.').last;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg'; // Par défaut
      }

      developer.log('Content-Type: $contentType', name: 'AppwriteService');

      // Upload photo file
      final inputFile = InputFile.fromBytes(
        bytes: fileBytes,
        filename: fileName,
        contentType: contentType,
      );

      final fileId = ID.unique();
      developer.log('🔄 Tentative upload photo vers bucket: $mediasBucketId avec ID: $fileId', name: 'AppwriteService');

      final file = await storage.createFile(
        bucketId: mediasBucketId,
        fileId: fileId,
        file: inputFile,
      );

      developer.log('✅ Photo uploadée: $fileId, file object: ${file.runtimeType}', name: 'AppwriteService');

      // Créer un document dans la collection photos pour modération
      final photoDoc = await databases.createDocument(
        databaseId: databaseId,
        collectionId: photosCollectionId,
        documentId: ID.unique(),
        data: {
          'userID': userId, // CORRIGÉ: userID avec I majuscule
          'fileId': fileId,
          'createdAt': DateTime.now().toIso8601String(),
          'isApproved': true, // TODO: Mettre false pour modération en production
          'isPhotoProfile': false, // CORRIGÉ: isPhotoProfile (Pas la photo de profil par défaut)
          'displayOrder': 0,
        },
      );

      developer.log('📸 Document photo créé: ${photoDoc.$id}', name: 'AppwriteService');

      // Mettre à jour le profil utilisateur avec le fileId de la photo
      try {
        final userProfile = await databases.getDocument(
          databaseId: databaseId,
          collectionId: usersCollectionId,
          documentId: userId,
        );

        final currentPhotoUrls = List<String>.from(userProfile.data['photoUrls'] ?? []);
        currentPhotoUrls.add(fileId);

        await databases.updateDocument(
          databaseId: databaseId,
          collectionId: usersCollectionId,
          documentId: userId,
          data: {'photoUrls': currentPhotoUrls},
        );

        developer.log('✅ Profil mis à jour avec photoId: $fileId', name: 'AppwriteService');
      } catch (e) {
        developer.log('⚠️ Impossible de mettre à jour le profil: $e', name: 'AppwriteService');
      }

      developer.log('✅ Photo uploadée et approuvée automatiquement', name: 'AppwriteService');

      // Retourner l'URL complète pour l'UI
      return getPhotoUrl(fileId);
    } catch (e) {
      developer.log('❌ Erreur upload photo: $e', name: 'AppwriteService');
      rethrow;
    }
  }

  // Delete profile photo
  Future<void> deleteProfilePhoto({
    required String userId,
    required String fileId,
  }) async {
    try {
      // Supprimer le fichier du storage
      await storage.deleteFile(
        bucketId: mediasBucketId,
        fileId: fileId,
      );

      // Mettre à jour le profil utilisateur
      final userProfile = await getUserProfile(userId);
      final currentPhotoUrls = List<String>.from(userProfile.data['photoUrls'] ?? []);
      currentPhotoUrls.remove(fileId); // Supprimer le fileId, pas l'URL

      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
        data: {'photoUrls': currentPhotoUrls},
      );

      developer.log('✅ Photo supprimée', name: 'AppwriteService');
    } catch (e) {
      developer.log('❌ Erreur suppression photo: $e', name: 'AppwriteService');
      rethrow;
    }
  }

  // ==================== LIKES ====================

  // Récupérer les likes envoyés
  Future<dynamic> getLikesSent() async {
    try {
      final user = await account.get();
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: likesCollectionId,
        queries: [
          Query.equal('userId', user.$id),
        ],
      );
      return response;
    } catch (e) {
      developer.log('❌ Erreur getLikesSent: $e', name: 'AppwriteService');
      rethrow;
    }
  }

  // Récupérer les likes reçus sur les vidéos
  Future<dynamic> getLikesReceived() async {
    try {
      final user = await account.get();

      // Récupérer toutes les vidéos de l'utilisateur
      final userVideos = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        queries: [
          Query.equal('userId', user.$id),
        ],
      );

      if (userVideos.documents.isEmpty) {
        return {'documents': []};
      }

      // Récupérer les likes sur ces vidéos
      final videoIds = userVideos.documents.map((doc) => doc.$id).toList();
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: videoLikesCollectionId,
        queries: [
          Query.equal('videoId', videoIds),
        ],
      );

      return response;
    } catch (e) {
      developer.log('❌ Erreur getLikesReceived: $e', name: 'AppwriteService');
      rethrow;
    }
  }

  // Récupérer les vidéos likées par l'utilisateur
  Future<dynamic> getLikedVideos() async {
    try {
      final user = await account.get();
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: videoLikesCollectionId,
        queries: [
          Query.equal('userId', user.$id),
        ],
      );
      return response; // Retourner directement l'objet DocumentList
    } catch (e) {
      developer.log('❌ Erreur getLikedVideos: $e', name: 'AppwriteService');
      rethrow;
    }
  }

  // Liker une vidéo
  Future<dynamic> likeVideo(String videoId) async {
    try {
      final user = await account.get();
      developer.log('❤️ Like vidéo: $videoId par user: ${user.$id}', name: 'AppwriteService');

      // Vérifier si déjà liké
      final existing = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: videoLikesCollectionId,
        queries: [
          Query.equal('userId', user.$id),
          Query.equal('videoId', videoId),
        ],
      );

      if (existing.documents.isNotEmpty) {
        // Compter le nombre total de likes pour cette vidéo
        final allLikes = await databases.listDocuments(
          databaseId: databaseId,
          collectionId: videoLikesCollectionId,
          queries: [
            Query.equal('videoId', videoId),
          ],
        );

        return {
          'success': true,
          'likeId': existing.documents.first.$id,
          'alreadyLiked': true,
          'totalLikes': allLikes.documents.length,
        };
      }

      // Créer le like
      final userId = user.$id;

      // Vérifier que userId n'est pas vide
      if (userId.isEmpty) {
        developer.log('❌ userId est vide!', name: 'AppwriteService');
        throw Exception('Utilisateur non authentifié - userId vide');
      }

      developer.log('🔍 Création like avec userId: $userId, videoId: $videoId', name: 'AppwriteService');

      final now = DateTime.now().toIso8601String();

      final like = await databases.createDocument(
        databaseId: databaseId,
        collectionId: videoLikesCollectionId,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'videoId': videoId,
          'timestamp': now,  // Attribut personnalisé requis dans Appwrite Cloud
          // $createdAt est géré automatiquement par Appwrite
        },
      );

      developer.log('✅ Document like créé: ${like.$id}', name: 'AppwriteService');

      // Compter le nombre total de likes pour cette vidéo
      final allLikes = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: videoLikesCollectionId,
        queries: [
          Query.equal('videoId', videoId),
        ],
      );

      final totalLikes = allLikes.documents.length;

      // Mettre à jour le compteur de likes dans le document vidéo
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        documentId: videoId,
        data: {
          'likes': totalLikes,
        },
      );

      developer.log('✅ Like créé, total: $totalLikes', name: 'AppwriteService');

      return {
        'success': true,
        'likeId': like.$id,
        'alreadyLiked': false,
        'totalLikes': totalLikes,
      };
    } catch (e) {
      developer.log('❌ Erreur likeVideo: $e', name: 'AppwriteService');
      developer.log('❌ Type erreur: ${e.runtimeType}', name: 'AppwriteService');

      // Afficher l'erreur complète pour debug
      print('🔴 ERREUR COMPLETE likeVideo:');
      print('   VideoId: $videoId');
      try {
        final user = await account.get();
        print('   UserId: ${user.$id}');
      } catch (authError) {
        print('   UserId: [ERREUR AUTH] $authError');
      }
      print('   Type: ${e.runtimeType}');
      print('   Message: $e');

      rethrow;
    }
  }

  // Retirer le like d'une vidéo
  Future<dynamic> unlikeVideo(String videoId) async {
    try {
      final user = await account.get();
      developer.log('💔 Unlike vidéo: $videoId', name: 'AppwriteService');

      // Trouver le like existant
      final existing = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: videoLikesCollectionId,
        queries: [
          Query.equal('userId', user.$id),
          Query.equal('videoId', videoId),
        ],
      );

      if (existing.documents.isEmpty) {
        developer.log('⚠️ Aucun like trouvé pour cette vidéo', name: 'AppwriteService');

        // Compter quand même le total
        final allLikes = await databases.listDocuments(
          databaseId: databaseId,
          collectionId: videoLikesCollectionId,
          queries: [
            Query.equal('videoId', videoId),
          ],
        );

        return {
          'success': false,
          'notLiked': true,
          'totalLikes': allLikes.documents.length,
        };
      }

      // Supprimer le like
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: videoLikesCollectionId,
        documentId: existing.documents.first.$id,
      );

      // Compter le nombre total de likes restants pour cette vidéo
      final allLikes = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: videoLikesCollectionId,
        queries: [
          Query.equal('videoId', videoId),
        ],
      );

      final totalLikes = allLikes.documents.length;

      // Mettre à jour le compteur de likes dans le document vidéo
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        documentId: videoId,
        data: {
          'likes': totalLikes,
        },
      );

      developer.log('✅ Like supprimé, total: $totalLikes', name: 'AppwriteService');

      return {
        'success': true,
        'totalLikes': totalLikes,
      };
    } catch (e) {
      developer.log('❌ Erreur unlikeVideo: $e', name: 'AppwriteService');
      rethrow;
    }
  }

  // Récupérer une vidéo par son ID
  Future<dynamic> getVideo(String videoId) async {
    try {
      final video = await databases.getDocument(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        documentId: videoId,
      );
      return video;
    } catch (e) {
      developer.log('❌ Erreur getVideo: $e', name: 'AppwriteService');
      rethrow;
    }
  }

  // Incrémenter le compteur de vues d'une vidéo
  Future<dynamic> incrementVideoView(String videoId) async {
    try {
      developer.log('👁️ Incrémentation vue pour vidéo: $videoId', name: 'AppwriteService');

      // Récupérer la vidéo actuelle
      final video = await databases.getDocument(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        documentId: videoId,
      );

      final currentViews = video.data['views'] ?? 0;
      final newViews = currentViews + 1;

      // Mettre à jour le compteur de vues
      final updatedVideo = await databases.updateDocument(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        documentId: videoId,
        data: {
          'views': newViews,
        },
      );

      developer.log('✅ Vue incrémentée: $newViews vues', name: 'AppwriteService');

      return {
        'success': true,
        'videoId': videoId,
        'totalViews': newViews,
      };
    } catch (e) {
      developer.log('❌ Erreur incrementVideoView: $e', name: 'AppwriteService');
      rethrow;
    }
  }

  // ==================== MATCHES ====================

  // Vérifier si un match existe avec un utilisateur
  Future<bool> checkMatch(String userId) async {
    try {
      final currentUser = await account.get();

      // Chercher un match dans les deux sens
      final matches = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: matchesCollectionId,
        queries: [
          Query.or([
            Query.and([
              Query.equal('user1Id', currentUser.$id),
              Query.equal('user2Id', userId),
            ]),
            Query.and([
              Query.equal('user1Id', userId),
              Query.equal('user2Id', currentUser.$id),
            ]),
          ]),
        ],
      );

      return matches.documents.isNotEmpty;
    } catch (e) {
      developer.log('❌ Erreur checkMatch: $e', name: 'AppwriteService');
      return false;
    }
  }

  // Récupérer le nombre de matches
  Future<int> getMatchesCount() async {
    try {
      final user = await account.get();
      final matches = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: matchesCollectionId,
        queries: [
          Query.or([
            Query.equal('user1Id', user.$id),
            Query.equal('user2Id', user.$id),
          ]),
        ],
      );

      return matches.documents.length;
    } catch (e) {
      developer.log('❌ Erreur getMatchesCount: $e', name: 'AppwriteService');
      return 0;
    }
  }

  // ==================== REPORTS & BLOCKING ====================
  // Délégation vers AppwriteReportsService

  Future<dynamic> reportUser({
    required String reportedUserId,
    required String reportType,
    required String description,
  }) => reportsService.reportUser(
        reportedUserId: reportedUserId,
        reportType: reportType,
        description: description,
      );

  Future<dynamic> blockUser(String blockedUserId, {String? reason}) =>
      reportsService.blockUser(blockedUserId, reason: reason);

  Future<void> unblockUser(String blockedUserId) =>
      reportsService.unblockUser(blockedUserId);

  Future<dynamic> getBlockedUsers() => reportsService.getBlockedUsers();

  Future<bool> isUserBlocked(String userId) =>
      reportsService.isUserBlocked(userId);

  // ==================== CHAT ====================
  // Délégation vers AppwriteChatService

  Future<dynamic> sendMessage({
    required String matchId,
    required String receiverId,
    required String message,
    String? mediaUrl,
  }) => chatService.sendMessage(
        matchId: matchId,
        receiverId: receiverId,
        message: message,
        mediaUrl: mediaUrl,
      );

  Future<dynamic> getMessages({
    required String matchId,
    int limit = 50,
    int offset = 0,
  }) => chatService.getMessages(
        matchId: matchId,
        limit: limit,
        offset: offset,
      );

  Future<void> markMessagesAsRead(String matchId) =>
      chatService.markMessagesAsRead(matchId);

  Future<int> getUnreadMessagesCount() => chatService.getUnreadMessagesCount();

  StreamSubscription subscribeToMessages({
    required String matchId,
    required Function(dynamic) onMessage,
  }) => chatService.subscribeToMessages(
        matchId: matchId,
        onMessage: onMessage,
      );

  // === MODERATION ===

  /// Approuver une vidéo
  Future<void> approveVideo(String videoId) async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        documentId: videoId,
        data: {'isApproved': true},
      );
      print('✅ Vidéo $videoId approuvée');
    } catch (e) {
      print('❌ Erreur approbation vidéo: $e');
      rethrow;
    }
  }

  /// Rejeter une vidéo (la marquer comme non approuvée)
  Future<void> rejectVideo(String videoId) async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        documentId: videoId,
        data: {'isApproved': false},
      );
      print('❌ Vidéo $videoId rejetée');
    } catch (e) {
      print('❌ Erreur rejet vidéo: $e');
      rethrow;
    }
  }

  /// Supprimer une vidéo rejetée
  Future<void> deleteRejectedVideo(String videoId, String fileId) async {
    try {
      // Supprimer le fichier
      await storage.deleteFile(bucketId: mediasBucketId, fileId: fileId);
      // Supprimer le document
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: videosCollectionId,
        documentId: videoId,
      );
      print('🗑️ Vidéo $videoId supprimée');
    } catch (e) {
      print('❌ Erreur suppression vidéo: $e');
      rethrow;
    }
  }

  // === TYPING INDICATOR ===

  Future<void> sendTypingIndicator({
    required String matchId,
    required String userId,
    required bool isTyping,
  }) async {
    // Appwrite Realtime permet d'utiliser un document temporaire ou un channel custom
    // Pour simplifier, on peut utiliser la collection messages avec un type spécial
    // Ou créer une collection dédiée "typing_indicators"
    // Ici on utilise un event custom via realtime
    try {
      // Créer un document temporaire dans une collection typing_indicators
      // avec TTL de 10 secondes
      if (isTyping) {
        await databases.createDocument(
          databaseId: databaseId,
          collectionId: 'typing_indicators', // À créer dans Appwrite
          documentId: 'typing_${matchId}_$userId',
          data: {
            'matchId': matchId,
            'userId': userId,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } else {
        try {
          await databases.deleteDocument(
            databaseId: databaseId,
            collectionId: 'typing_indicators',
            documentId: 'typing_${matchId}_$userId',
          );
        } catch (e) {
          // Ignore si le document n'existe pas
        }
      }
    } catch (e) {
      developer.log('⚠️ Erreur sendTypingIndicator: $e', name: 'AppwriteService');
    }
  }

  dynamic subscribeToTypingIndicator({
    required String matchId,
    required Function(String userId, bool isTyping) onTypingChange,
  }) {
    try {
      final channel = 'databases.$databaseId.collections.typing_indicators.documents';

      final subscription = realtime.subscribe([channel]);

      subscription.stream.listen(
        (response) {
          try {
            final data = response.payload;
            if (data != null && data['matchId'] == matchId) {
              final userId = data['userId'] as String;
              final isTyping = response.events.contains('databases.*.collections.*.documents.*.create');
              onTypingChange(userId, isTyping);

              // Auto-supprimer après 5 secondes
              if (isTyping) {
                Future.delayed(const Duration(seconds: 5), () {
                  try {
                    databases.deleteDocument(
                      databaseId: databaseId,
                      collectionId: 'typing_indicators',
                      documentId: 'typing_${matchId}_$userId',
                    );
                  } catch (e) {
                    // Ignore
                  }
                });
              }
            }
          } catch (e) {
            developer.log('⚠️ Erreur Realtime typing: $e', name: 'AppwriteService');
          }
        },
        onError: (error) {
          developer.log('⚠️ Erreur stream Realtime: $error', name: 'AppwriteService');
        },
      );

      return subscription;
    } catch (e) {
      developer.log('⚠️ Erreur subscribeToTypingIndicator: $e', name: 'AppwriteService');
      return null;
    }
  }
}