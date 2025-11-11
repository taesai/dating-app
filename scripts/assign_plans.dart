import 'package:appwrite/appwrite.dart';
import 'dart:math';

void main() async {
  // Configuration
  const projectId = '68e7d31c0038917ac217';
  const databaseId = '68e8a9320008c0036625';
  const collectionId = '68e8a94100036164036c';
  const endpoint = 'http://localhost/v1';
  const apiKey = 'VOTRE_API_KEY_ICI'; // Remplacez par votre API Key

  print('🚀 Démarrage du script d\'attribution des plans...\n');

  // Initialiser le client Appwrite
  final client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setKey(apiKey);

  final databases = Databases(client);

  try {
    // Récupérer tous les utilisateurs
    print('📥 Récupération des utilisateurs...');
    final response = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: [
        Query.limit(100),
      ],
    );

    final users = response.documents;
    print('✅ ${users.length} utilisateurs trouvés\n');

    if (users.isEmpty) {
      print('⚠️ Aucun utilisateur à mettre à jour');
      return;
    }

    // Plans et probabilités
    final plans = ['free', 'silver', 'gold'];
    final weights = [60, 30, 10]; // 60% FREE, 30% SILVER, 10% GOLD

    String getRandomPlan() {
      final random = Random().nextInt(100);
      var cumulative = 0;
      for (var i = 0; i < plans.length; i++) {
        cumulative += weights[i];
        if (random < cumulative) {
          return plans[i];
        }
      }
      return 'free';
    }

    DateTime? getExpirationDate(String plan) {
      if (plan == 'free') return null;
      return DateTime.now().add(const Duration(days: 30));
    }

    DateTime? getStartDate(String plan) {
      if (plan == 'free') return null;
      return DateTime.now();
    }

    print('🎲 Attribution aléatoire des plans...\n');

    var updated = 0;
    var errors = 0;

    for (final user in users) {
      try {
        final plan = getRandomPlan();
        final expiresAt = getExpirationDate(plan);
        final startedAt = getStartDate(plan);

        // Préparer les données
        final data = <String, dynamic>{
          'subscriptionPlan': plan,
        };

        // Ajouter les dates seulement pour SILVER et GOLD
        if (plan != 'free') {
          data['subscriptionExpiresAt'] = expiresAt!.toIso8601String();
          data['subscriptionStartedAt'] = startedAt!.toIso8601String();
        }

        // Mettre à jour
        await databases.updateDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: user.$id,
          data: data,
        );

        final planEmoji = plan == 'free' ? '🆓' : plan == 'silver' ? '🥈' : '🥇';
        print('$planEmoji ${user.data['name'] ?? user.$id} → ${plan.toUpperCase()}');
        updated++;
      } catch (e) {
        print('❌ Erreur pour ${user.data['name'] ?? user.$id}: $e');
        errors++;
      }
    }

    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ Mise à jour terminée!');
    print('📊 $updated utilisateurs mis à jour');
    if (errors > 0) {
      print('⚠️ $errors erreurs rencontrées');
    }

    // Statistiques finales
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 Récupération des statistiques...');

    final finalResponse = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: [Query.limit(100)],
    );

    final stats = <String, int>{};
    for (final user in finalResponse.documents) {
      final plan = user.data['subscriptionPlan'] ?? 'free';
      stats[plan] = (stats[plan] ?? 0) + 1;
    }

    print('📊 Distribution des plans:');
    print('   🆓 FREE: ${stats['free'] ?? 0} utilisateurs');
    print('   🥈 SILVER: ${stats['silver'] ?? 0} utilisateurs');
    print('   🥇 GOLD: ${stats['gold'] ?? 0} utilisateurs');
  } catch (e) {
    print('\n❌ ERREUR GLOBALE: $e');
  }
}
