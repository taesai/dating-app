import 'dart:io';
import 'dart:convert';
import 'package:appwrite/appwrite.dart';

/// Script pour analyser la structure de votre Appwrite local
/// et générer un rapport complet pour la migration vers le Cloud
void main() async {
  print('═══════════════════════════════════════════════════════');
  print('📊 ANALYSE DE LA STRUCTURE APPWRITE LOCALE');
  print('═══════════════════════════════════════════════════════');
  print('');

  // Configuration Appwrite LOCAL
  final client = Client()
    ..setEndpoint('http://localhost/v1')
    ..setProject('68e7d31c0038917ac217')
    ..setKey('YOUR_API_KEY_HERE'); // ⚠️ Vous devez créer une API Key dans Appwrite Console

  final databases = Databases(client);
  final storage = Storage(client);

  const databaseId = '68e8a9320008c0036625';

  try {
    print('🔍 Analyse de la base de données...\n');

    // 1. Lister toutes les collections
    final collectionsResponse = await databases.listCollections(
      databaseId: databaseId,
    );

    print('✅ ${collectionsResponse.total} collections trouvées\n');
    print('═══════════════════════════════════════════════════════');

    final Map<String, dynamic> structure = {
      'databaseId': databaseId,
      'collections': [],
    };

    for (var collection in collectionsResponse.collections) {
      print('\n📦 Collection: ${collection.name}');
      print('   ID: ${collection.$id}');
      print('   Permissions: ${collection.$permissions}');
      print('   Document Security: ${collection.documentSecurity}');

      final collectionData = {
        'id': collection.$id,
        'name': collection.name,
        'permissions': collection.$permissions,
        'documentSecurity': collection.documentSecurity,
        'attributes': [],
        'indexes': [],
        'documentCount': 0,
      };

      // Compter les documents
      try {
        final docs = await databases.listDocuments(
          databaseId: databaseId,
          collectionId: collection.$id,
        );
        collectionData['documentCount'] = docs.total;
        print('   📄 ${docs.total} documents');
      } catch (e) {
        print('   ⚠️ Impossible de compter les documents: $e');
      }

      // Lister les attributs
      print('   Attributs:');
      final attributes = collection.attributes;
      for (var attr in attributes) {
        final attrData = {
          'key': attr['key'],
          'type': attr['type'],
          'required': attr['required'] ?? false,
          'array': attr['array'] ?? false,
          'size': attr['size'],
          'default': attr['default'],
        };

        collectionData['attributes'].add(attrData);

        print('      - ${attr['key']} (${attr['type']})${attr['required'] == true ? ' *requis*' : ''}');
      }

      // Lister les index
      print('   Index:');
      final indexes = collection.indexes;
      for (var index in indexes) {
        final indexData = {
          'key': index['key'],
          'type': index['type'],
          'attributes': index['attributes'],
        };

        collectionData['indexes'].add(indexData);

        print('      - ${index['key']} (${index['type']}): ${index['attributes']}');
      }

      structure['collections'].add(collectionData);
      print('   ─────────────────────────────────────────────────');
    }

    // 2. Lister les buckets de stockage
    print('\n\n🗄️ BUCKETS DE STOCKAGE\n');
    print('═══════════════════════════════════════════════════════');

    try {
      final bucketsResponse = await storage.listBuckets();
      print('✅ ${bucketsResponse.total} buckets trouvés\n');

      structure['buckets'] = [];

      for (var bucket in bucketsResponse.buckets) {
        print('\n📦 Bucket: ${bucket.name}');
        print('   ID: ${bucket.$id}');
        print('   Permissions: ${bucket.$permissions}');
        print('   Max file size: ${bucket.maximumFileSize} bytes');
        print('   Allowed file extensions: ${bucket.allowedFileExtensions}');

        final bucketData = {
          'id': bucket.$id,
          'name': bucket.name,
          'permissions': bucket.$permissions,
          'maximumFileSize': bucket.maximumFileSize,
          'allowedFileExtensions': bucket.allowedFileExtensions,
          'compression': bucket.compression,
          'encryption': bucket.encryption,
          'antivirus': bucket.antivirus,
        };

        structure['buckets'].add(bucketData);

        // Compter les fichiers
        try {
          final files = await storage.listFiles(bucketId: bucket.$id);
          print('   📁 ${files.total} fichiers');
        } catch (e) {
          print('   ⚠️ Impossible de compter les fichiers: $e');
        }
      }
    } catch (e) {
      print('⚠️ Erreur lors de la récupération des buckets: $e');
    }

    // 3. Sauvegarder le rapport dans un fichier JSON
    print('\n\n💾 Sauvegarde du rapport...');
    final file = File('appwrite_structure_report.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(structure),
    );
    print('✅ Rapport sauvegardé dans: ${file.absolute.path}');

    // 4. Générer un script de migration
    print('\n\n📝 Génération du script de migration...');
    await _generateMigrationScript(structure);

    print('\n\n═══════════════════════════════════════════════════════');
    print('✅ ANALYSE TERMINÉE !');
    print('═══════════════════════════════════════════════════════');
    print('\nFichiers générés:');
    print('  1. appwrite_structure_report.json - Rapport complet');
    print('  2. migration_to_cloud.md - Instructions de migration');
    print('\nProchaines étapes:');
    print('  1. Créez une API Key dans Appwrite Console (Settings > API Keys)');
    print('  2. Remplacez YOUR_API_KEY_HERE dans ce script');
    print('  3. Relancez le script pour générer le rapport complet');
    print('  4. Suivez les instructions dans migration_to_cloud.md');

  } catch (e, stackTrace) {
    print('\n❌ ERREUR: $e');
    print('Stack trace: $stackTrace');
    print('\n⚠️ Assurez-vous que:');
    print('  1. Appwrite local est démarré (http://localhost)');
    print('  2. Vous avez créé une API Key dans Appwrite Console');
    print('  3. La clé API a les permissions nécessaires (Database, Storage)');
  }
}

Future<void> _generateMigrationScript(Map<String, dynamic> structure) async {
  final buffer = StringBuffer();

  buffer.writeln('# 📋 Guide de migration vers Appwrite Cloud');
  buffer.writeln('');
  buffer.writeln('## 🎯 Étape 1: Créer la structure dans Appwrite Cloud');
  buffer.writeln('');
  buffer.writeln('### Database');
  buffer.writeln('- Allez dans Appwrite Cloud Console');
  buffer.writeln('- Databases > Create Database');
  buffer.writeln('- Nom: `dating_app_db`');
  buffer.writeln('- Copiez le Database ID généré');
  buffer.writeln('');

  buffer.writeln('### Collections');
  buffer.writeln('');

  for (var collection in structure['collections']) {
    buffer.writeln('#### ${collection['name']}');
    buffer.writeln('');
    buffer.writeln('**Créer la collection:**');
    buffer.writeln('- Nom: `${collection['name']}`');
    buffer.writeln('- ID: `${collection['id']}` (ou laissez Appwrite générer)');
    buffer.writeln('- Document Security: ${collection['documentSecurity']}');
    buffer.writeln('');
    buffer.writeln('**Attributs à créer:**');
    buffer.writeln('```');
    for (var attr in collection['attributes']) {
      buffer.writeln('- ${attr['key']}: ${attr['type']}${attr['required'] ? ' (requis)' : ''}${attr['array'] ? ' (array)' : ''}');
    }
    buffer.writeln('```');
    buffer.writeln('');
    buffer.writeln('**Index:**');
    buffer.writeln('```');
    for (var index in collection['indexes']) {
      buffer.writeln('- ${index['key']}: ${index['type']} sur ${index['attributes']}');
    }
    buffer.writeln('```');
    buffer.writeln('');
    buffer.writeln('**Documents:** ${collection['documentCount']} à migrer');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');
  }

  buffer.writeln('### Buckets de stockage');
  buffer.writeln('');

  if (structure['buckets'] != null) {
    for (var bucket in structure['buckets']) {
      buffer.writeln('#### ${bucket['name']}');
      buffer.writeln('- ID: `${bucket['id']}`');
      buffer.writeln('- Max file size: ${bucket['maximumFileSize']} bytes');
      buffer.writeln('- Extensions autorisées: ${bucket['allowedFileExtensions']}');
      buffer.writeln('');
    }
  }

  buffer.writeln('## 🎯 Étape 2: Exporter les données locales');
  buffer.writeln('');
  buffer.writeln('Utilisez le script `export_local_data.dart` pour exporter toutes vos données.');
  buffer.writeln('');
  buffer.writeln('## 🎯 Étape 3: Importer dans le Cloud');
  buffer.writeln('');
  buffer.writeln('Utilisez le script `import_to_cloud.dart` pour importer les données.');
  buffer.writeln('');
  buffer.writeln('## 🎯 Étape 4: Mettre à jour la configuration Flutter');
  buffer.writeln('');
  buffer.writeln('```dart');
  buffer.writeln('// Dans lib/core/services/appwrite_service.dart');
  buffer.writeln('static const String endpoint = \'https://cloud.appwrite.io/v1\';');
  buffer.writeln('static const String projectId = \'VOTRE_PROJECT_ID_CLOUD\';');
  buffer.writeln('```');

  final file = File('migration_to_cloud.md');
  await file.writeAsString(buffer.toString());
  print('✅ Guide de migration généré: ${file.absolute.path}');
}
