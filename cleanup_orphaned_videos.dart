/// Script de nettoyage des documents vidéos orphelins (sans fichier correspondant)
import 'dart:io';
import 'dart:convert';

void main() async {
  // Configuration Appwrite Cloud
  const appwriteEndpoint = 'https://cloud.appwrite.io/v1';
  const appwriteProjectId = '681829e4003b243e6681';
  const appwriteApiKey = 'standard_7da9298dee3bcf5a59db7a953ff194e5db52e62638e7ceeab828afe0ac87654260972ae723dc53ddaa7d54002617cfdcb80dd9fa84762c207efe266d413bbe2104f4ec6e80d467d898bb9ef134e76a623a7b64add47a9e929cee7867b0af9ffd50500212d6b0cdf66a1dc8781e13439bfa238650b92bb990f7bbbb7356489e5b';
  const databaseId = '68db88f700374422bfc7';
  const videosCollectionId = 'videos';
  const usersCollectionId = 'users';
  const mediasBucketId = 'medias';

  final client = HttpClient();

  try {
    print('🔍 Récupération des documents vidéos...');

    // 1. Lister tous les documents vidéos
    final listVideosUri = Uri.parse(
      '$appwriteEndpoint/databases/$databaseId/collections/$videosCollectionId/documents',
    );

    final listVideosRequest = await client.getUrl(listVideosUri);
    listVideosRequest.headers.set('X-Appwrite-Project', appwriteProjectId);
    listVideosRequest.headers.set('X-Appwrite-Key', appwriteApiKey);

    final listVideosResponse = await listVideosRequest.close();
    final listVideosBody = await listVideosResponse.transform(utf8.decoder).join();
    final listVideosData = jsonDecode(listVideosBody);

    if (listVideosData['documents'] == null) {
      print('❌ Erreur: ${listVideosData['message'] ?? 'Réponse invalide'}');
      exit(1);
    }

    final videos = listVideosData['documents'] as List;
    print('📹 ${videos.length} documents vidéos trouvés\n');

    int deleted = 0;
    int kept = 0;
    int errors = 0;

    for (var video in videos) {
      final videoId = video['\$id'];
      final fileId = video['fileId'];
      final userId = video['userId'];
      final title = video['title'] ?? 'Sans titre';

      print('📹 Vidéo: $title (ID: $videoId)');
      print('   File ID: $fileId');

      // Vérifier si c'est une URL Cloudinary (garder)
      if (fileId.toString().startsWith('http')) {
        print('   ✅ URL Cloudinary - conservée');
        kept++;
        continue;
      }

      // Vérifier si le fichier existe dans le bucket
      try {
        final checkFileUri = Uri.parse(
          '$appwriteEndpoint/storage/buckets/$mediasBucketId/files/$fileId',
        );

        final checkFileRequest = await client.getUrl(checkFileUri);
        checkFileRequest.headers.set('X-Appwrite-Project', appwriteProjectId);
        checkFileRequest.headers.set('X-Appwrite-Key', appwriteApiKey);

        final checkFileResponse = await checkFileRequest.close();
        await checkFileResponse.drain(); // Consommer la réponse

        if (checkFileResponse.statusCode == 200) {
          print('   ✅ Fichier existe - conservée');
          kept++;
        } else if (checkFileResponse.statusCode == 404) {
          print('   ⚠️ Fichier n\'existe pas - ORPHELIN');
          print('   🗑️ Suppression du document...');

          // Supprimer le document vidéo
          final deleteVideoUri = Uri.parse(
            '$appwriteEndpoint/databases/$databaseId/collections/$videosCollectionId/documents/$videoId',
          );

          final deleteVideoRequest = await client.deleteUrl(deleteVideoUri);
          deleteVideoRequest.headers.set('X-Appwrite-Project', appwriteProjectId);
          deleteVideoRequest.headers.set('X-Appwrite-Key', appwriteApiKey);

          final deleteVideoResponse = await deleteVideoRequest.close();
          await deleteVideoResponse.drain();

          if (deleteVideoResponse.statusCode == 204) {
            print('   ✅ Document vidéo supprimé');

            // Retirer le videoId du profil utilisateur
            try {
              print('   📝 Mise à jour du profil utilisateur...');

              final getUserUri = Uri.parse(
                '$appwriteEndpoint/databases/$databaseId/collections/$usersCollectionId/documents/$userId',
              );

              final getUserRequest = await client.getUrl(getUserUri);
              getUserRequest.headers.set('X-Appwrite-Project', appwriteProjectId);
              getUserRequest.headers.set('X-Appwrite-Key', appwriteApiKey);

              final getUserResponse = await getUserRequest.close();
              final getUserBody = await getUserResponse.transform(utf8.decoder).join();
              final userData = jsonDecode(getUserBody);

              final videoIds = List<String>.from(userData['videoIds'] ?? []);
              videoIds.remove(videoId);

              final updateUserUri = Uri.parse(
                '$appwriteEndpoint/databases/$databaseId/collections/$usersCollectionId/documents/$userId',
              );

              final updateUserRequest = await client.patchUrl(updateUserUri);
              updateUserRequest.headers.set('X-Appwrite-Project', appwriteProjectId);
              updateUserRequest.headers.set('X-Appwrite-Key', appwriteApiKey);
              updateUserRequest.headers.set('Content-Type', 'application/json');

              final updateData = jsonEncode({
                'data': {'videoIds': videoIds}
              });

              updateUserRequest.write(updateData);
              final updateUserResponse = await updateUserRequest.close();
              await updateUserResponse.drain();

              if (updateUserResponse.statusCode == 200) {
                print('   ✅ Profil utilisateur mis à jour');
              }
            } catch (e) {
              print('   ⚠️ Erreur mise à jour profil: $e');
            }

            deleted++;
          } else {
            print('   ❌ Erreur suppression document: ${deleteVideoResponse.statusCode}');
            errors++;
          }
        } else {
          print('   ⚠️ Statut inattendu: ${checkFileResponse.statusCode}');
          errors++;
        }
      } catch (e) {
        print('   ❌ Erreur vérification: $e');
        errors++;
      }

      print('');
    }

    print('✅ Nettoyage terminé !');
    print('   - $deleted documents orphelins supprimés');
    print('   - $kept documents conservés');
    print('   - $errors erreurs');

    client.close();
  } catch (e) {
    print('❌ Erreur globale: $e');
    client.close();
    exit(1);
  }
}
