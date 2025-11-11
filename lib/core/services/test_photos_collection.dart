import 'package:appwrite/appwrite.dart';
import 'appwrite_service.dart';

/// Test simple pour vérifier si la collection photos fonctionne
class TestPhotosCollection {
  static Future<void> testCreatePhoto() async {
    final appwrite = AppwriteService();
    final databases = appwrite.databases;

    print('🧪 Test de création d\'un document dans la collection photos...');

    try {
      // Essayer de créer un document de test
      final testDoc = await databases.createDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.photosCollectionId,
        documentId: ID.unique(),
        data: {
          'userID': 'test-user-id', // CORRIGÉ: userID avec I majuscule
          'fileId': 'test-file-id',
          'createdAt': DateTime.now().toIso8601String(),
          'isApproved': false,
          'isPhotoProfile': false, // CORRIGÉ: isPhotoProfile
          'displayOrder': 0,
        },
      );

      print('✅ Test réussi ! Document créé avec ID: ${testDoc.$id}');
      print('📋 Data: ${testDoc.data}');

      // Supprimer le document de test
      await databases.deleteDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.photosCollectionId,
        documentId: testDoc.$id,
      );

      print('🗑️ Document de test supprimé');
      print('');
      print('✅ La collection photos fonctionne correctement !');
      print('   Le problème doit venir d\'autre chose...');

    } catch (e) {
      print('❌ Test échoué !');
      print('   Erreur: $e');
      print('');
      print('🔍 Vérifications à faire :');
      print('   1. La collection "photos" existe-t-elle dans Appwrite Console ?');
      print('   2. Collection ID est-il bien : ${AppwriteService.photosCollectionId}');
      print('   3. Les attributs sont-ils tous créés ?');
      print('      - userID (string) ⚠️ ATTENTION: userID avec I majuscule');
      print('      - fileId (string)');
      print('      - createdAt (datetime)');
      print('      - isApproved (boolean)');
      print('      - isPhotoProfile (boolean) ⚠️ ATTENTION: isPhotoProfile');
      print('      - displayOrder (integer)');
      print('   4. Les permissions permettent-elles la création ?');
      print('      - Any ou Users → create');
    }
  }

  static Future<void> testListPhotos() async {
    final appwrite = AppwriteService();
    final databases = appwrite.databases;

    print('');
    print('🧪 Test de lecture de la collection photos...');

    try {
      final response = await databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.photosCollectionId,
      );

      print('✅ Lecture réussie !');
      print('   Nombre de documents: ${response.documents.length}');

    } catch (e) {
      print('❌ Lecture échouée !');
      print('   Erreur: $e');
    }
  }
}
