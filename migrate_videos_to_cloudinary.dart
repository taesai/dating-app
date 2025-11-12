/// Script de migration des vidéos depuis Appwrite Storage vers Cloudinary CDN
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

void main() async {
  // Configuration Appwrite Cloud
  const appwriteEndpoint = 'https://cloud.appwrite.io/v1';
  const appwriteProjectId = '681829e4003b243e6681';
  const appwriteApiKey = 'standard_7da9298dee3bcf5a59db7a953ff194e5db52e62638e7ceeab828afe0ac87654260972ae723dc53ddaa7d54002617cfdcb80dd9fa84762c207efe266d413bbe2104f4ec6e80d467d898bb9ef134e76a623a7b64add47a9e929cee7867b0af9ffd50500212d6b0cdf66a1dc8781e13439bfa238650b92bb990f7bbbb7356489e5b';
  const databaseId = '68db88f700374422bfc7';
  const videosCollectionId = 'videos';
  const mediasBucketId = 'medias';

  // Configuration Cloudinary
  const cloudinaryName = 'dpfwub9rb';
  const cloudinaryApiKey = '752743795153795';
  const cloudinaryApiSecret = 'AtMKJ7wbsBRho-XnJjv40XsOLKI';
  const cloudinaryFolder = 'dating_app/videos';

  final client = HttpClient();

  try {
    print('🔍 Récupération des vidéos depuis Appwrite...');

    // 1. Lister toutes les vidéos dans la collection
    final listUri = Uri.parse(
      '$appwriteEndpoint/databases/$databaseId/collections/$videosCollectionId/documents',
    );

    final listRequest = await client.getUrl(listUri);
    listRequest.headers.set('X-Appwrite-Project', appwriteProjectId);
    listRequest.headers.set('X-Appwrite-Key', appwriteApiKey);
    listRequest.headers.set('Content-Type', 'application/json');

    final listResponse = await listRequest.close();
    final listBody = await listResponse.transform(utf8.decoder).join();
    final listData = jsonDecode(listBody);

    if (listData['documents'] == null) {
      print('❌ Erreur: ${listData['message'] ?? 'Réponse invalide'}');
      exit(1);
    }

    final videos = listData['documents'] as List;
    print('📹 ${videos.length} vidéos trouvées');

    int migrated = 0;
    int skipped = 0;
    int errors = 0;

    for (var video in videos) {
      final videoId = video['\$id'];
      final fileId = video['fileId'];
      final userId = video['userId'];
      final title = video['title'] ?? 'Sans titre';

      // Vérifier si c'est déjà une URL Cloudinary
      if (fileId.toString().startsWith('http')) {
        print('✅ Vidéo $videoId déjà migrée vers Cloudinary');
        skipped++;
        continue;
      }

      print('\n📤 Migration de la vidéo: $title (ID: $videoId)');
      print('   File ID Appwrite: $fileId');

      try {
        // 2. Télécharger le fichier depuis Appwrite Storage
        print('   ⬇️ Téléchargement depuis Appwrite...');
        final downloadUri = Uri.parse(
          '$appwriteEndpoint/storage/buckets/$mediasBucketId/files/$fileId/view?project=$appwriteProjectId',
        );

        final downloadRequest = await client.getUrl(downloadUri);
        // Pas besoin de headers pour /view quand File Security est désactivé

        final downloadResponse = await downloadRequest.close();

        if (downloadResponse.statusCode != 200) {
          print('   ❌ Erreur téléchargement: ${downloadResponse.statusCode}');
          print('   URL tentée: $downloadUri');
          errors++;
          continue;
        }

        // Récupérer les bytes
        final videoBytes = await downloadResponse
            .fold<List<int>>([], (previous, element) => previous..addAll(element));

        print('   ✅ Téléchargé: ${videoBytes.length} bytes');

        // 3. Uploader vers Cloudinary
        print('   ⬆️ Upload vers Cloudinary...');

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final publicId = '$cloudinaryFolder/${userId}_$timestamp';

        final uploadUri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudinaryName/video/upload',
        );

        final uploadRequest = await client.postUrl(uploadUri);
        uploadRequest.headers.set('Content-Type', 'multipart/form-data; boundary=----boundary');

        // Créer le body multipart manuellement
        final boundary = '----boundary';
        var body = <int>[];

        // Ajouter public_id
        body.addAll(utf8.encode('--$boundary\r\n'));
        body.addAll(utf8.encode('Content-Disposition: form-data; name="public_id"\r\n\r\n'));
        body.addAll(utf8.encode('$publicId\r\n'));

        // Ajouter api_key
        body.addAll(utf8.encode('--$boundary\r\n'));
        body.addAll(utf8.encode('Content-Disposition: form-data; name="api_key"\r\n\r\n'));
        body.addAll(utf8.encode('$cloudinaryApiKey\r\n'));

        // Ajouter timestamp
        body.addAll(utf8.encode('--$boundary\r\n'));
        body.addAll(utf8.encode('Content-Disposition: form-data; name="timestamp"\r\n\r\n'));
        body.addAll(utf8.encode('$timestamp\r\n'));

        // Ajouter signature (simple pour ce script)
        final signature = '${publicId}_${timestamp}_$cloudinaryApiSecret'.hashCode.toString();
        body.addAll(utf8.encode('--$boundary\r\n'));
        body.addAll(utf8.encode('Content-Disposition: form-data; name="signature"\r\n\r\n'));
        body.addAll(utf8.encode('$signature\r\n'));

        // Ajouter le fichier vidéo
        body.addAll(utf8.encode('--$boundary\r\n'));
        body.addAll(utf8.encode(
            'Content-Disposition: form-data; name="file"; filename="video_$videoId.mp4"\r\n'));
        body.addAll(utf8.encode('Content-Type: video/mp4\r\n\r\n'));
        body.addAll(videoBytes);
        body.addAll(utf8.encode('\r\n'));

        // Terminer
        body.addAll(utf8.encode('--$boundary--\r\n'));

        uploadRequest.contentLength = body.length;
        uploadRequest.add(body);

        final uploadResponse = await uploadRequest.close();
        final uploadBody = await uploadResponse.transform(utf8.decoder).join();

        if (uploadResponse.statusCode == 200) {
          final uploadData = jsonDecode(uploadBody);
          final cloudinaryUrl = uploadData['secure_url'] as String;

          print('   ✅ Uploadé vers Cloudinary: $cloudinaryUrl');

          // 4. Mettre à jour le document vidéo dans Appwrite avec la nouvelle URL
          print('   📝 Mise à jour du document Appwrite...');

          final updateUri = Uri.parse(
            '$appwriteEndpoint/databases/$databaseId/collections/$videosCollectionId/documents/$videoId',
          );

          final updateRequest = await client.patchUrl(updateUri);
          updateRequest.headers.set('X-Appwrite-Project', appwriteProjectId);
          updateRequest.headers.set('X-Appwrite-Key', appwriteApiKey);
          updateRequest.headers.set('Content-Type', 'application/json');

          final updateData = jsonEncode({
            'data': {
              'fileId': cloudinaryUrl,
            }
          });

          updateRequest.write(updateData);
          final updateResponse = await updateRequest.close();
          final updateResponseBody = await updateResponse.transform(utf8.decoder).join();

          if (updateResponse.statusCode == 200) {
            print('   ✅ Document mis à jour avec succès');
            migrated++;
          } else {
            print('   ⚠️ Erreur mise à jour document: ${updateResponse.statusCode}');
            print('   Response: $updateResponseBody');
            errors++;
          }
        } else {
          print('   ❌ Erreur upload Cloudinary: ${uploadResponse.statusCode}');
          print('   Response: $uploadBody');
          errors++;
        }
      } catch (e) {
        print('   ❌ Erreur migration vidéo $videoId: $e');
        errors++;
      }
    }

    print('\n✅ Migration terminée !');
    print('   - $migrated vidéos migrées vers Cloudinary');
    print('   - $skipped vidéos déjà migrées (ignorées)');
    print('   - $errors erreurs');

    client.close();
  } catch (e) {
    print('❌ Erreur globale: $e');
    client.close();
    exit(1);
  }
}
