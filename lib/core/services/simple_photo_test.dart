import 'package:appwrite/appwrite.dart';
import 'appwrite_service.dart';

/// Test ultra-simple pour diagnostiquer le problème de la collection photos
class SimplePhotoTest {
  static Future<void> runDiagnostic() async {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('🔍 DIAGNOSTIC DE LA COLLECTION PHOTOS');
    print('═══════════════════════════════════════════════════════');
    print('');

    final appwrite = AppwriteService();
    final databases = appwrite.databases;

    // Test 1 : Vérifier la connexion à la database
    print('📝 Test 1: Vérification de la connexion à la database...');
    print('   Database ID: ${AppwriteService.databaseId}');
    print('   Collection ID: ${AppwriteService.photosCollectionId}');
    print('');

    // Test 2 : Essayer de lire la collection
    print('📝 Test 2: Lecture de la collection photos...');
    try {
      final response = await databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.photosCollectionId,
      );
      print('   ✅ Lecture OK - ${response.documents.length} documents trouvés');
      print('');
    } catch (e) {
      print('   ❌ ERREUR DE LECTURE: $e');
      print('   → Vérifiez que la collection existe dans Appwrite Console');
      print('   → Vérifiez l\'ID de la collection');
      print('');
      return;
    }

    // Test 3 : Essayer de créer un document de test
    print('📝 Test 3: Création d\'un document de test...');
    String? testDocId;
    try {
      final testDoc = await databases.createDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.photosCollectionId,
        documentId: ID.unique(),
        data: {
          'userID': 'TEST_USER_ID', // CORRIGÉ: userID avec I majuscule
          'fileId': 'TEST_FILE_ID',
          'createdAt': DateTime.now().toIso8601String(),
          'isApproved': false,
          'isPhotoProfile': false, // CORRIGÉ: isPhotoProfile
          'displayOrder': 0,
        },
      );
      testDocId = testDoc.$id;
      print('   ✅ Création OK - Document ID: $testDocId');
      print('');
    } catch (e) {
      print('   ❌ ERREUR DE CRÉATION: $e');
      print('');

      final errorStr = e.toString();

      if (errorStr.contains('Missing required attribute')) {
        print('   💡 SOLUTION:');
        print('      Un attribut requis est manquant dans la collection.');
        print('      Vérifiez que TOUS ces attributs existent dans Appwrite Console:');
        print('      - userID (string, required) ⚠️ ATTENTION: userID avec I majuscule');
        print('      - fileId (string, required)');
        print('      - createdAt (datetime, required)');
        print('      - isApproved (boolean, required, default: false)');
        print('      - isPhotoProfile (boolean, required, default: false) ⚠️ ATTENTION: isPhotoProfile');
        print('      - displayOrder (integer, required, default: 0)');
      } else if (errorStr.contains('Unauthorized') || errorStr.contains('permissions')) {
        print('   💡 SOLUTION:');
        print('      Problème de permissions.');
        print('      Dans Appwrite Console → Database → photos → Settings → Permissions:');
        print('      Ajoutez: Role: Any → Create, Read, Update, Delete');
      } else if (errorStr.contains('Collection') || errorStr.contains('not found')) {
        print('   💡 SOLUTION:');
        print('      La collection n\'existe pas ou l\'ID est incorrect.');
        print('      Vérifiez l\'ID dans Appwrite Console.');
      } else {
        print('   💡 Erreur inconnue. Vérifiez les logs ci-dessus.');
      }
      print('');
      return;
    }

    // Test 4 : Supprimer le document de test
    print('📝 Test 4: Suppression du document de test...');
    try {
      await databases.deleteDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.photosCollectionId,
        documentId: testDocId!,
      );
      print('   ✅ Suppression OK');
      print('');
    } catch (e) {
      print('   ❌ ERREUR DE SUPPRESSION: $e');
      print('');
    }

    // Test 5 : Vérifier un utilisateur réel
    print('📝 Test 5: Vérification des utilisateurs...');
    try {
      final usersResponse = await appwrite.getAllUsers();
      print('   ✅ ${usersResponse.documents.length} utilisateurs trouvés');

      if (usersResponse.documents.isNotEmpty) {
        final firstUser = usersResponse.documents.first;
        final userData = firstUser.data;
        final photoUrls = List<String>.from(userData['photoUrls'] ?? []);
        print('   Premier utilisateur: ${firstUser.$id}');
        print('   Nombre de photos: ${photoUrls.length}');

        if (photoUrls.isNotEmpty) {
          print('   Exemple de fileId: ${photoUrls.first}');
        }
      }
      print('');
    } catch (e) {
      print('   ❌ ERREUR: $e');
      print('');
    }

    print('═══════════════════════════════════════════════════════');
    print('✅ DIAGNOSTIC TERMINÉ');
    print('═══════════════════════════════════════════════════════');
    print('');
  }
}
