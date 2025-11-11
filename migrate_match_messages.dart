import 'package:appwrite/appwrite.dart';

/// Script de migration pour mettre à jour tous les documents match
/// avec les informations du dernier message (lastMessage, lastMessageSenderId, lastMessageDate)
///
/// Usage: flutter run migrate_match_messages.dart -d chrome

void main() async {
  // Configuration Appwrite
  const String endpoint = 'http://localhost/v1';
  const String projectId = '68e7d31c0038917ac217';
  const String databaseId = '68e8a9320008c0036625';
  const String matchesCollectionId = '68e8a96e0037016de109';
  const String chatMessagesCollectionId = '68f0a82f002a6e6724ec';

  print('🚀 Démarrage de la migration...');

  // Initialiser le client Appwrite
  final client = Client()
    ..setEndpoint(endpoint)
    ..setProject(projectId)
    ..setSelfSigned(status: true);

  final databases = Databases(client);

  try {
    // 1. Récupérer tous les matches
    print('📥 Récupération de tous les matches...');
    final matchesResponse = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: matchesCollectionId,
    );

    print('✅ ${matchesResponse.documents.length} matches trouvés');

    int updatedCount = 0;
    int skippedCount = 0;
    int errorCount = 0;

    // 2. Pour chaque match, trouver le dernier message
    for (final matchDoc in matchesResponse.documents) {
      final matchId = matchDoc.$id;

      try {
        // Récupérer tous les messages pour ce match, triés par date décroissante
        final messagesResponse = await databases.listDocuments(
          databaseId: databaseId,
          collectionId: chatMessagesCollectionId,
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
            databaseId: databaseId,
            collectionId: matchesCollectionId,
            documentId: matchId,
            data: {
              'lastMessage': messageText,
              'lastMessageSenderId': senderId,
              'lastMessageDate': createdAt,
            },
          );

          updatedCount++;
          print('✅ Match $matchId mis à jour (dernier message de $senderId)');
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
  }
}
