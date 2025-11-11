import 'package:appwrite/appwrite.dart';
import 'appwrite_service.dart';

/// Service de migration pour mettre à jour les documents match
class MigrationService {
  /// Mettre à jour tous les matches avec les informations du dernier message
  static Future<Map<String, int>> migrateMatchLastMessages() async {
    final appwrite = AppwriteService();
    final databases = appwrite.databases;

    print('🚀 Démarrage de la migration des matches...');

    int updatedCount = 0;
    int skippedCount = 0;
    int errorCount = 0;

    try {
      // 1. Récupérer tous les matches
      print('📥 Récupération de tous les matches...');
      final matchesResponse = await databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.matchesCollectionId,
      );

      print('✅ ${matchesResponse.documents.length} matches trouvés');

      // 2. Pour chaque match, trouver le dernier message
      for (final matchDoc in matchesResponse.documents) {
        final matchId = matchDoc.$id;

        try {
          // Récupérer tous les messages pour ce match, triés par date décroissante
          final messagesResponse = await databases.listDocuments(
            databaseId: AppwriteService.databaseId,
            collectionId: AppwriteService.chatMessagesCollectionId,
            queries: [
              Query.equal('matchId', matchId),
              Query.orderDesc('createdAt'),
              Query.limit(1),
            ],
          );

          // S'il y a au moins un message
          if (messagesResponse.documents.isNotEmpty) {
            final lastMessage = messagesResponse.documents.first;
            final messageText = lastMessage.data['message'] as String;
            final senderId = lastMessage.data['senderId'] as String;
            final createdAt = lastMessage.data['createdAt'] as String;

            // Mettre à jour le document match
            await databases.updateDocument(
              databaseId: AppwriteService.databaseId,
              collectionId: AppwriteService.matchesCollectionId,
              documentId: matchId,
              data: {
                'lastMessage': messageText,
                'lastMessageSenderId': senderId,
                'lastMessageDate': createdAt,
              },
            );

            updatedCount++;
            print('✅ Match $matchId mis à jour');
          } else {
            skippedCount++;
            print('ℹ️ Match $matchId ignoré (aucun message)');
          }
        } catch (e) {
          errorCount++;
          print('❌ Erreur pour match $matchId: $e');
        }
      }

      // 3. Afficher le résumé
      print('');
      print('═══════════════════════════════════════');
      print('📊 RÉSUMÉ DE LA MIGRATION');
      print('═══════════════════════════════════════');
      print('✅ Matches mis à jour: $updatedCount');
      print('ℹ️ Matches ignorés (pas de messages): $skippedCount');
      print('❌ Erreurs: $errorCount');
      print('📦 Total traité: ${matchesResponse.documents.length}');
      print('═══════════════════════════════════════');

      if (errorCount > 0) {
        print('⚠️ Migration terminée avec des erreurs');
      } else {
        print('🎉 Migration terminée avec succès!');
      }
    } catch (e) {
      print('💥 Erreur fatale: $e');
      errorCount++;
    }

    return {
      'updated': updatedCount,
      'skipped': skippedCount,
      'errors': errorCount,
    };
  }
}
