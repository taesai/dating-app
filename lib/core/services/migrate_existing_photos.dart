import 'package:appwrite/appwrite.dart';
import 'appwrite_service.dart';

/// Service pour migrer les photos existantes vers la collection photos
class MigrateExistingPhotos {
  /// Migrer toutes les photos existantes des utilisateurs vers la collection photos
  static Future<Map<String, int>> migrateAllPhotos() async {
    final appwrite = AppwriteService();
    final databases = appwrite.databases;

    print('🚀 Démarrage de la migration des photos...');

    int photosCreated = 0;
    int usersProcessed = 0;
    int errorCount = 0;

    try {
      // 1. Récupérer tous les utilisateurs
      print('📥 Récupération de tous les utilisateurs...');
      final usersResponse = await appwrite.getAllUsers();

      print('✅ ${usersResponse.documents.length} utilisateurs trouvés');

      // 2. Pour chaque utilisateur, migrer ses photos
      for (final userDoc in usersResponse.documents) {
        final userId = userDoc.$id; // Définir userId ici pour qu'il soit accessible dans le catch
        try {
          final userData = userDoc.data;
          final photoUrls = List<String>.from(userData['photoUrls'] ?? []);

          if (photoUrls.isEmpty) {
            print('ℹ️ Utilisateur $userId sans photos');
            continue;
          }

          print('📸 Migration de ${photoUrls.length} photos pour utilisateur $userId');

          int photoOrder = 0;
          for (final fileId in photoUrls) {
            try {
              // Vérifier si la photo existe déjà dans la collection
              final existingPhotos = await databases.listDocuments(
                databaseId: AppwriteService.databaseId,
                collectionId: AppwriteService.photosCollectionId,
                queries: [
                  Query.equal('fileId', fileId),
                ],
              );

              if (existingPhotos.documents.isNotEmpty) {
                print('⏭️ Photo $fileId déjà migrée');
                continue;
              }

              // Créer le document photo (déjà approuvé car c'est une photo existante)
              await databases.createDocument(
                databaseId: AppwriteService.databaseId,
                collectionId: AppwriteService.photosCollectionId,
                documentId: ID.unique(),
                data: {
                  'userID': userId, // CORRIGÉ: userID avec I majuscule
                  'fileId': fileId,
                  'createdAt': DateTime.now().toIso8601String(),
                  'isApproved': true, // Photos existantes déjà approuvées
                  'isPhotoProfile': photoOrder == 0, // CORRIGÉ: isPhotoProfile (Première photo = photo de profil)
                  'displayOrder': photoOrder,
                },
              );

              photosCreated++;
              photoOrder++;
              print('✅ Photo $fileId migrée');

            } catch (e) {
              errorCount++;
              print('❌ Erreur migration photo $fileId pour user $userId: $e');
              print('   Stack trace: ${StackTrace.current}');
            }
          }

          usersProcessed++;
          print('✅ Utilisateur $userId traité (${photoUrls.length} photos)');

        } catch (e, stackTrace) {
          errorCount++;
          print('❌ Erreur traitement utilisateur $userId: $e');
          print('   Stack trace: $stackTrace');
        }
      }

      // 3. Afficher le résumé
      print('');
      print('═══════════════════════════════════════');
      print('📊 RÉSUMÉ DE LA MIGRATION');
      print('═══════════════════════════════════════');
      print('✅ Photos créées: $photosCreated');
      print('👤 Utilisateurs traités: $usersProcessed');
      print('❌ Erreurs: $errorCount');
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
      'photosCreated': photosCreated,
      'usersProcessed': usersProcessed,
      'errors': errorCount,
    };
  }
}
