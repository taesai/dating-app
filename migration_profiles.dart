import 'package:appwrite/appwrite.dart';

void main() async {
  final client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject('68e8a7cf0010b0b2d01e')
    ..setSelfSigned(status: true);

  final databases = Databases(client);

  print('🔄 Début migration isProfileApproved...');

  try {
    final response = await databases.listDocuments(
      databaseId: '68e8a8380013e56ef87c',
      collectionId: '68e8a84e00274f7fa92f',
    );

    print('📊 ${response.documents.length} utilisateurs trouvés');

    int updated = 0;
    for (var doc in response.documents) {
      final currentValue = doc.data['isProfileApproved'];
      print('User ${doc.data['name']} - isProfileApproved actuel: $currentValue');

      await databases.updateDocument(
        databaseId: '68e8a8380013e56ef87c',
        collectionId: '68e8a84e00274f7fa92f',
        documentId: doc.$id,
        data: {'isProfileApproved': false},
      );
      updated++;
      print('  ✅ Mis à jour');
    }

    print('✅ Migration terminée: $updated profils mis à jour');
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
