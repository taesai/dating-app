import 'dart:convert';
import 'dart:io';
import 'migration_config.dart';

/// Script pour mettre à jour tous les profils existants dans Appwrite Cloud
/// Ajoute isApproved: true à tous les utilisateurs existants
void main() async {
  print('═══════════════════════════════════════════════════════');
  print('🔄 MISE À JOUR DES PROFILS EXISTANTS');
  print('═══════════════════════════════════════════════════════');
  print('');
  print('Ce script va mettre à jour tous les profils existants');
  print('dans Appwrite Cloud avec isApproved: true');
  print('');

  try {
    final updater = ProfileUpdater();
    await updater.updateAllProfiles();
    print('');
    print('✅ MISE À JOUR TERMINÉE');
  } catch (e) {
    print('');
    print('❌ ERREUR: $e');
    exit(1);
  }
}

class ProfileUpdater {
  final String endpoint = MigrationConfig.cloudEndpoint;
  final String projectId = MigrationConfig.cloudProjectId;
  final String apiKey = MigrationConfig.cloudApiKey;
  final String databaseId = MigrationConfig.cloudDatabaseId;
  final String usersCollectionId = 'users';

  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$endpoint$path');
      final request = await client.openUrl(method, uri);

      // Headers
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('X-Appwrite-Project', projectId);
      request.headers.set('X-Appwrite-Key', apiKey);

      // Body
      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody);
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${responseBody}');
      }
    } finally {
      client.close();
    }
  }

  Future<void> updateAllProfiles() async {
    print('📡 Connexion à Appwrite Cloud...');
    print('   Database: $databaseId');
    print('   Collection: $usersCollectionId');
    print('');

    // 1. Récupérer tous les documents de la collection users
    print('📥 Récupération de tous les utilisateurs...');
    final response = await _makeRequest(
      'GET',
      '/databases/$databaseId/collections/$usersCollectionId/documents?limit=100',
    );

    final documents = response['documents'] as List;
    print('✅ ${documents.length} utilisateurs trouvés');
    print('');

    // 2. Mettre à jour chaque document
    int successCount = 0;
    int errorCount = 0;

    for (var doc in documents) {
      final userId = doc['\$id'];
      final email = doc['email'] ?? 'N/A';
      final currentIsApproved = doc['isProfileApproved'];

      print('🔄 Mise à jour: $email (ID: $userId)');
      print('   isProfileApproved actuel: $currentIsApproved');

      try {
        // Vérifier si isProfileApproved existe déjà et est true
        if (currentIsApproved == true) {
          print('   ℹ️ Déjà approuvé, mise à jour ignorée');
          successCount++;
          print('');
          continue;
        }

        if (currentIsApproved == null) {
          print('   ⚠️ Attribut isProfileApproved manquant, ajout...');
        } else {
          print('   📝 Mise à jour de isProfileApproved: false → true');
        }

        // Mettre à jour le document avec isActive aussi pour éviter l'erreur "missing payload"
        await _makeRequest(
          'PATCH',
          '/databases/$databaseId/collections/$usersCollectionId/documents/$userId',
          body: {
            'isProfileApproved': true,
            'isActive': true,
          },
        );

        print('   ✅ Mis à jour avec succès');
        successCount++;
      } catch (e) {
        print('   ❌ Erreur: $e');
        errorCount++;
      }

      print('');

      // Rate limiting - pause entre chaque requête
      await Future.delayed(Duration(milliseconds: 300));
    }

    print('═══════════════════════════════════════════════════════');
    print('📊 RÉSUMÉ');
    print('═══════════════════════════════════════════════════════');
    print('Total: ${documents.length} utilisateurs');
    print('✅ Succès: $successCount');
    print('❌ Erreurs: $errorCount');
  }
}
