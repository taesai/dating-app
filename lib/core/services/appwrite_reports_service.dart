import 'package:appwrite/appwrite.dart';
import 'dart:developer' as developer;

/// Service pour gérer les signalements et blocages dans Appwrite
class AppwriteReportsService {
  final Databases databases;
  final Account account;
  final String databaseId;
  final String reportsCollectionId;
  final String blockedUsersCollectionId;

  AppwriteReportsService({
    required this.databases,
    required this.account,
    required this.databaseId,
    required this.reportsCollectionId,
    required this.blockedUsersCollectionId,
  });

  // ==================== REPORTS ====================

  /// Signaler un utilisateur
  Future<dynamic> reportUser({
    required String reportedUserId,
    required String reportType,
    required String description,
  }) async {
    try {
      final user = await account.get();
      developer.log('🚨 Signalement utilisateur: $reportedUserId', name: 'AppwriteReports');

      final report = await databases.createDocument(
        databaseId: databaseId,
        collectionId: reportsCollectionId,
        documentId: ID.unique(),
        data: {
          'reporterId': user.$id,
          'reportedUserId': reportedUserId,
          'reportType': reportType,
          'description': description,
          'createdAt': DateTime.now().toIso8601String(),
          'status': 'pending',
        },
      );

      developer.log('✅ Signalement créé: ${report.$id}', name: 'AppwriteReports');
      return report;
    } catch (e) {
      developer.log('❌ Erreur reportUser: $e', name: 'AppwriteReports');
      rethrow;
    }
  }

  // ==================== BLOCKING ====================

  /// Bloquer un utilisateur
  Future<dynamic> blockUser(String blockedUserId, {String? reason}) async {
    try {
      final user = await account.get();
      developer.log('🚫 Blocage utilisateur: $blockedUserId', name: 'AppwriteReports');

      // Vérifier si déjà bloqué
      final existing = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: blockedUsersCollectionId,
        queries: [
          Query.equal('blockerId', user.$id),
          Query.equal('blockedUserId', blockedUserId),
        ],
      );

      if (existing.documents.isNotEmpty) {
        developer.log('⚠️ Utilisateur déjà bloqué', name: 'AppwriteReports');
        return existing.documents.first;
      }

      final block = await databases.createDocument(
        databaseId: databaseId,
        collectionId: blockedUsersCollectionId,
        documentId: ID.unique(),
        data: {
          'blockerId': user.$id,
          'blockedUserId': blockedUserId,
          'reason': reason,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      developer.log('✅ Utilisateur bloqué: ${block.$id}', name: 'AppwriteReports');
      return block;
    } catch (e) {
      developer.log('❌ Erreur blockUser: $e', name: 'AppwriteReports');
      rethrow;
    }
  }

  /// Débloquer un utilisateur
  Future<void> unblockUser(String blockedUserId) async {
    try {
      final user = await account.get();
      developer.log('✅ Déblocage utilisateur: $blockedUserId', name: 'AppwriteReports');

      final blocks = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: blockedUsersCollectionId,
        queries: [
          Query.equal('blockerId', user.$id),
          Query.equal('blockedUserId', blockedUserId),
        ],
      );

      if (blocks.documents.isNotEmpty) {
        await databases.deleteDocument(
          databaseId: databaseId,
          collectionId: blockedUsersCollectionId,
          documentId: blocks.documents.first.$id,
        );
        developer.log('✅ Utilisateur débloqué', name: 'AppwriteReports');
      }
    } catch (e) {
      developer.log('❌ Erreur unblockUser: $e', name: 'AppwriteReports');
      rethrow;
    }
  }

  /// Récupérer la liste des utilisateurs bloqués
  Future<dynamic> getBlockedUsers() async {
    try {
      final user = await account.get();
      final blocks = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: blockedUsersCollectionId,
        queries: [
          Query.equal('blockerId', user.$id),
        ],
      );
      return blocks;
    } catch (e) {
      developer.log('❌ Erreur getBlockedUsers: $e', name: 'AppwriteReports');
      rethrow;
    }
  }

  /// Vérifier si un utilisateur est bloqué
  Future<bool> isUserBlocked(String userId) async {
    try {
      final user = await account.get();
      final blocks = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: blockedUsersCollectionId,
        queries: [
          Query.equal('blockerId', user.$id),
          Query.equal('blockedUserId', userId),
        ],
      );
      return blocks.documents.isNotEmpty;
    } catch (e) {
      developer.log('❌ Erreur isUserBlocked: $e', name: 'AppwriteReports');
      return false;
    }
  }
}
