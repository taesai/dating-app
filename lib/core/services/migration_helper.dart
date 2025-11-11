import 'appwrite_service.dart';

/// Helper pour migrer les données existantes vers le nouveau système d'approbation
class MigrationHelper {
  final AppwriteService _appwriteService = AppwriteService();

  /// Mettre à jour toutes les vidéos existantes pour ajouter isApproved = false
  Future<void> migrateVideosToApprovalSystem() async {
    try {
      print('🔄 Migration: Mise à jour des vidéos existantes...');

      // Récupérer toutes les vidéos
      final response = await _appwriteService.getVideos(limit: 500);
      final videos = response.documents;

      int updatedCount = 0;
      int skippedCount = 0;

      for (var videoDoc in videos) {
        final videoData = videoDoc.data;
        final videoId = videoDoc.$id;

        // Vérifier si isApproved existe déjà
        if (videoData['isApproved'] == null) {
          try {
            await _appwriteService.databases.updateDocument(
              databaseId: AppwriteService.databaseId,
              collectionId: AppwriteService.videosCollectionId,
              documentId: videoId,
              data: {'isApproved': false},
            );
            updatedCount++;
            print('✅ Vidéo $videoId mise à jour');
          } catch (e) {
            print('❌ Erreur vidéo $videoId: $e');
          }
        } else {
          skippedCount++;
        }
      }

      print('✅ Migration terminée: $updatedCount vidéos mises à jour, $skippedCount ignorées');
    } catch (e) {
      print('❌ Erreur migration: $e');
    }
  }

  /// Migrer les photos depuis photoUrls vers la nouvelle collection photos
  Future<void> migratePhotosToCollection() async {
    try {
      print('🔄 Migration: Conversion des photos vers la nouvelle collection...');

      // Récupérer tous les utilisateurs
      final response = await _appwriteService.getAllUsers();
      final users = response.documents;

      int migratedPhotos = 0;

      for (var userDoc in users) {
        final userData = userDoc.data;
        final userId = userDoc.$id;
        final photoUrls = List<String>.from(userData['photoUrls'] ?? []);

        if (photoUrls.isEmpty) continue;

        print('📸 Migration photos pour utilisateur $userId: ${photoUrls.length} photos');

        for (int i = 0; i < photoUrls.length; i++) {
          final fileId = photoUrls[i];

          try {
            // Créer un document photo dans la nouvelle collection
            await _appwriteService.databases.createDocument(
              databaseId: AppwriteService.databaseId,
              collectionId: AppwriteService.photosCollectionId,
              documentId: 'unique()',
              data: {
                'userId': userId,
                'fileId': fileId,
                'createdAt': DateTime.now().toIso8601String(),
                'isApproved': false, // Nécessite approbation
                'isProfilePhoto': i == 0, // La première est la photo de profil
                'displayOrder': i,
              },
            );
            migratedPhotos++;
            print('✅ Photo $fileId migrée');
          } catch (e) {
            print('❌ Erreur photo $fileId: $e');
          }
        }
      }

      print('✅ Migration terminée: $migratedPhotos photos migrées');
    } catch (e) {
      print('❌ Erreur migration photos: $e');
    }
  }
}
