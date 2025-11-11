import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Script pour corriger la valeur par défaut de isProfileApproved dans Appwrite
///
/// Ce script va:
/// 1. Se connecter à Appwrite avec une clé API admin
/// 2. Mettre à jour tous les utilisateurs ayant isProfileApproved = true sans raison
/// 3. Corriger l'attribut par défaut dans la collection

void main() async {
  // Configuration Appwrite Cloud
  const endpoint = 'https://cloud.appwrite.io/v1';
  const projectId = '681829e4003b243e6681';

  print('🔧 Correction de isProfileApproved dans Appwrite');
  print('================================================\n');

  // Demander la clé API
  print('Pour corriger la collection, vous devez vous connecter à Appwrite Console:');
  print('1. Allez sur https://cloud.appwrite.io/console/project-$projectId');
  print('2. Databases > dating_db > users');
  print('3. Attributes > isProfileApproved');
  print('4. Modifier la valeur par défaut: décocher ou mettre false');
  print('');
  print('Appuyez sur Entrée quand c\'est fait...');
  stdin.readLineSync();

  // Demander si on veut corriger les utilisateurs existants
  print('\nVoulez-vous mettre isProfileApproved = false pour tous les utilisateurs existants?');
  print('(cela nécessite une clé API avec permissions d\'écriture)');
  print('y/n: ');
  final response = stdin.readLineSync();

  if (response?.toLowerCase() != 'y') {
    print('✅ Terminé');
    return;
  }

  print('\nEntrez votre clé API Appwrite (Settings > API Keys):');
  final apiKey = stdin.readLineSync();

  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Clé API non fournie');
    return;
  }

  print('\n🔄 Correction des utilisateurs existants...');

  try {
    // 1. Récupérer tous les utilisateurs
    final usersUrl = '$endpoint/databases/dating_db/collections/users/documents?limit=100';
    final usersResponse = await http.get(
      Uri.parse(usersUrl),
      headers: {
        'X-Appwrite-Project': projectId,
        'X-Appwrite-Key': apiKey,
      },
    );

    if (usersResponse.statusCode != 200) {
      print('❌ Erreur récupération utilisateurs: ${usersResponse.statusCode}');
      print(usersResponse.body);
      return;
    }

    final usersData = jsonDecode(usersResponse.body);
    final users = usersData['documents'] as List;

    print('📋 ${users.length} utilisateurs trouvés');

    // 2. Mettre à jour chaque utilisateur
    int updated = 0;
    for (var user in users) {
      final userId = user['\$id'];
      final userName = user['name'] ?? 'Inconnu';
      final isApproved = user['isProfileApproved'];

      // Mettre à false si true ou null
      if (isApproved == true || isApproved == null) {
        print('🔄 Mise à jour: $userName (isProfileApproved: $isApproved → false)');

        final updateUrl = '$endpoint/databases/dating_db/collections/users/documents/$userId';
        final updateResponse = await http.patch(
          Uri.parse(updateUrl),
          headers: {
            'X-Appwrite-Project': projectId,
            'X-Appwrite-Key': apiKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'isProfileApproved': false}),
        );

        if (updateResponse.statusCode == 200) {
          updated++;
        } else {
          print('   ⚠️ Erreur: ${updateResponse.statusCode}');
        }

        // Pause pour éviter rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        print('✓ $userName déjà à false');
      }
    }

    print('\n✅ Terminé! $updated utilisateurs mis à jour');
    print('');
    print('📝 Note: Les nouveaux utilisateurs auront maintenant isProfileApproved = false par défaut');
    print('   Un admin devra les approuver manuellement depuis le dashboard admin.');

  } catch (e) {
    print('❌ Erreur: $e');
  }
}
