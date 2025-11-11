import 'package:appwrite/appwrite.dart';

void main() async {
  final client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject('68e8a7cf0010b0b2d01e')
    ..setKey('standard_2bc85f9fef36dbb38f9a8edb0a01e9a79e4f79f464a6e0c6a1ecf0ff17e1e3bd6f37f5ccdb03ab0d64f69284bae8cd7dfabc12f90b88bfd4a7b0ec46d88e4adce28e15225e4ccb833fddc88b9e659f7f1ac9d08c7fad2c8f5e23a9ad074aca8e30f2cce165ac86c7a7e08a88ec4fb88baabbe4c0a35e016bfc74e2a7c98f02b3'); // Votre API key

  final databases = Databases(client);

  print('🔄 Mise à jour forcée de tous les utilisateurs...');

  try {
    final response = await databases.listDocuments(
      databaseId: '68e8a8380013e56ef87c',
      collectionId: '68e8a84e00274f7fa92f',
    );

    print('📊 ${response.documents.length} utilisateurs trouvés');

    for (var doc in response.documents) {
      final name = doc.data['name'] ?? 'Unknown';

      // Forcer la mise à jour avec isProfileApproved = false
      await databases.updateDocument(
        databaseId: '68e8a8380013e56ef87c',
        collectionId: '68e8a84e00274f7fa92f',
        documentId: doc.\$id,
        data: {
          'isProfileApproved': false,
        },
      );

      print('✅ User $name mis à jour');
    }

    print('✅ Terminé!');
  } catch (e, stackTrace) {
    print('❌ Erreur: $e');
    print(stackTrace);
  }
}
