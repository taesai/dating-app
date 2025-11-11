import 'package:appwrite/appwrite.dart';
import 'dart:developer' as developer;
import 'dart:async';

/// Service pour gérer le chat dans Appwrite
class AppwriteChatService {
  final Databases databases;
  final Account account;
  final Realtime realtime;
  final String databaseId;
  final String chatMessagesCollectionId;
  final String matchesCollectionId;

  AppwriteChatService({
    required this.databases,
    required this.account,
    required this.realtime,
    required this.databaseId,
    required this.chatMessagesCollectionId,
    required this.matchesCollectionId,
  });

  // ==================== CHAT ====================

  /// Envoyer un message
  Future<dynamic> sendMessage({
    required String matchId,
    required String receiverId,
    required String message,
    String? mediaUrl,
  }) async {
    try {
      final user = await account.get();
      developer.log('💬 Envoi message à: $receiverId', name: 'AppwriteChat');

      final now = DateTime.now().toIso8601String();

      final chatMessage = await databases.createDocument(
        databaseId: databaseId,
        collectionId: chatMessagesCollectionId,
        documentId: ID.unique(),
        data: {
          'matchId': matchId,
          'senderId': user.$id,
          'receiverId': receiverId,
          'message': message,
          'timestamp': now,  // Attribut personnalisé requis dans Appwrite Cloud
          'isRead': false,
          'mediaUrl': mediaUrl,
          // $createdAt est géré automatiquement par Appwrite
        },
      );

      // Mettre à jour le document match avec le dernier message
      try {
        await databases.updateDocument(
          databaseId: databaseId,
          collectionId: matchesCollectionId,
          documentId: matchId,
          data: {
            'lastMessage': message,
            'lastMessageSenderId': user.$id,
            'lastMessageDate': now,
          },
        );
        developer.log('✅ Match mis à jour avec dernier message', name: 'AppwriteChat');
      } catch (e) {
        developer.log('⚠️ Erreur mise à jour match: $e', name: 'AppwriteChat');
        // Ne pas bloquer l'envoi du message si la mise à jour du match échoue
      }

      developer.log('✅ Message envoyé: ${chatMessage.$id}', name: 'AppwriteChat');
      return chatMessage;
    } catch (e) {
      developer.log('❌ Erreur sendMessage: $e', name: 'AppwriteChat');
      print('🔴 Erreur complète envoi message:');
      print('   matchId: $matchId');
      print('   receiverId: $receiverId');
      print('   message: $message');
      print('   erreur: $e');
      rethrow;
    }
  }

  /// Récupérer les messages d'une conversation
  Future<dynamic> getMessages({
    required String matchId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      developer.log('📨 Chargement messages pour match: $matchId', name: 'AppwriteChat');

      // Trier par timestamp (attribut personnalisé dans Appwrite Cloud)
      final messages = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: chatMessagesCollectionId,
        queries: [
          Query.equal('matchId', matchId),
          Query.orderDesc('timestamp'),  // Utiliser timestamp au lieu de createdAt
          Query.limit(limit),
          Query.offset(offset),
        ],
      );
      return messages;
    } catch (e) {
      developer.log('❌ Erreur getMessages: $e', name: 'AppwriteChat');
      developer.log('❌ Détails erreur: ${e.runtimeType}', name: 'AppwriteChat');
      print('🔴 Erreur complète getMessages: $e');
      rethrow;
    }
  }

  /// Marquer les messages comme lus
  Future<void> markMessagesAsRead(String matchId) async {
    try {
      final user = await account.get();

      // Récupérer les messages non lus
      final unreadMessages = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: chatMessagesCollectionId,
        queries: [
          Query.equal('matchId', matchId),
          Query.equal('receiverId', user.$id),
          Query.equal('isRead', false),
        ],
      );

      // Marquer chaque message comme lu
      for (final message in unreadMessages.documents) {
        await databases.updateDocument(
          databaseId: databaseId,
          collectionId: chatMessagesCollectionId,
          documentId: message.$id,
          data: {'isRead': true},
        );
      }

      developer.log('✅ ${unreadMessages.documents.length} messages marqués comme lus', name: 'AppwriteChat');
    } catch (e) {
      developer.log('❌ Erreur markMessagesAsRead: $e', name: 'AppwriteChat');
      rethrow;
    }
  }

  /// Compter les messages non lus
  Future<int> getUnreadMessagesCount() async {
    try {
      final user = await account.get();
      final unreadMessages = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: chatMessagesCollectionId,
        queries: [
          Query.equal('receiverId', user.$id),
          Query.equal('isRead', false),
        ],
      );
      return unreadMessages.documents.length;
    } catch (e) {
      developer.log('❌ Erreur getUnreadMessagesCount: $e', name: 'AppwriteChat');
      return 0;
    }
  }

  /// S'abonner aux nouveaux messages (Realtime)
  StreamSubscription subscribeToMessages({
    required String matchId,
    required Function(dynamic) onMessage,
  }) {
    developer.log('🔔 Abonnement aux messages: $matchId', name: 'AppwriteChat');

    final subscription = realtime.subscribe([
      'databases.$databaseId.collections.$chatMessagesCollectionId.documents'
    ]);

    return subscription.stream.listen(
      (response) {
        try {
          if (response.events.contains('databases.*.collections.*.documents.*.create')) {
            final payload = response.payload;
            if (payload != null && payload is Map && payload['matchId'] == matchId) {
              onMessage(payload);
            }
          }
        } catch (e) {
          developer.log('⚠️ Erreur Realtime chat: $e', name: 'AppwriteChatService');
        }
      },
      onError: (error) {
        developer.log('⚠️ Erreur stream Realtime: $error', name: 'AppwriteChatService');
      },
    );
  }
}
