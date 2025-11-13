/// Script pour corriger les coordonnées GPS des utilisateurs
/// Ce script attribue des coordonnées aléatoires réalistes dans différentes villes

import 'dart:io';
import 'dart:math';
import 'package:appwrite/appwrite.dart';

void main() async {
  // Configuration Appwrite Cloud
  final client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject('681829e4003b243e6681')
      .setKey('standard_3c06bede19fcadba22dc926761c94e1356782de9d73e253bb68fafa5d928ac448983705cf7ac2bbbd30d99f864286331599059e678df3652cff674c93419e8d11c592196a68963be3a5723a83c3aecc46a9bd51ec7de49bc183b0050efef095f3a7b6f364e354a6382578455c602e9a952575c5f0355a240b7ae1c3857f30eb7');

  final databases = Databases(client);

  const databaseId = '68db88f700374422bfc7';
  const usersCollectionId = 'users';

  // Villes avec coordonnées réelles
  final cities = [
    {'name': 'Paris', 'lat': 48.8566, 'lng': 2.3522},
    {'name': 'Lyon', 'lat': 45.7640, 'lng': 4.8357},
    {'name': 'Marseille', 'lat': 43.2965, 'lng': 5.3698},
    {'name': 'Toulouse', 'lat': 43.6047, 'lng': 1.4442},
    {'name': 'Nice', 'lat': 43.7102, 'lng': 7.2620},
    {'name': 'Nantes', 'lat': 47.2184, 'lng': -1.5536},
    {'name': 'Bordeaux', 'lat': 44.8378, 'lng': -0.5792},
    {'name': 'Lille', 'lat': 50.6292, 'lng': 3.0573},
    {'name': 'Montpellier', 'lat': 43.6108, 'lng': 3.8767},
    {'name': 'Strasbourg', 'lat': 48.5734, 'lng': 7.7521},
  ];

  try {
    print('🔍 Récupération des utilisateurs...');

    // Récupérer tous les utilisateurs
    final response = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: usersCollectionId,
    );

    print('👥 ${response.documents.length} utilisateurs trouvés');

    int updated = 0;
    int skipped = 0;

    for (var doc in response.documents) {
      final userId = doc.$id;
      final currentLat = doc.data['latitude'] ?? 0.0;
      final currentLng = doc.data['longitude'] ?? 0.0;

      // Vérifier si les coordonnées sont invalides (0,0)
      if (currentLat == 0.0 && currentLng == 0.0) {
        // Choisir une ville aléatoire
        final city = cities[updated % cities.length];

        // Ajouter un petit décalage aléatoire (0-5km autour de la ville)
        final random = Random();
        final randomLat = city['lat']! + (random.nextDouble() - 0.5) * 0.05;
        final randomLng = city['lng']! + (random.nextDouble() - 0.5) * 0.05;

        print('📍 Mise à jour ${doc.data['name']} → ${city['name']} ($randomLat, $randomLng)');

        await databases.updateDocument(
          databaseId: databaseId,
          collectionId: usersCollectionId,
          documentId: userId,
          data: {
            'latitude': randomLat,
            'longitude': randomLng,
            'city': city['name'],
          },
        );

        updated++;
      } else {
        print('✅ ${doc.data['name']} a déjà des coordonnées valides');
        skipped++;
      }
    }

    print('\n✅ Migration terminée !');
    print('   - $updated utilisateurs mis à jour');
    print('   - $skipped utilisateurs ignorés (coordonnées déjà valides)');

  } catch (e) {
    print('❌ Erreur: $e');
    exit(1);
  }
}
