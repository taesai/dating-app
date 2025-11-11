import 'dart:io';
import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'migration_config.dart';

/// Étape 1 : Analyser la structure de l'Appwrite local
void main() async {
  print('═══════════════════════════════════════════════════════');
  print('📊 ÉTAPE 1 : ANALYSE DE LA STRUCTURE APPWRITE LOCALE');
  print('═══════════════════════════════════════════════════════');
  print('');

  // Configuration du client Appwrite LOCAL
  final client = Client()
    ..setEndpoint(MigrationConfig.localEndpoint)
    ..setProject(MigrationConfig.localProjectId)
    ..setKey(MigrationConfig.localApiKey);

  final databases = Databases(client);
  final storage = Storage(client);

  try {
    print('🔍 Connexion à Appwrite local...');
    print('   Endpoint: ${MigrationConfig.localEndpoint}');
    print('   Project: ${MigrationConfig.localProjectId}');
    print('');

    final structure = {
      'databaseId': MigrationConfig.localDatabaseId,
      'collections': <Map<String, dynamic>>[],
      'buckets': <Map<String, dynamic>>[],
    };

    // ═══════════════════════════════════════════════════════
    // 1. ANALYSER LES COLLECTIONS
    // ═══════════════════════════════════════════════════════
    print('📦 Analyse des collections...\n');

    final collectionsResponse = await databases.listCollections(
      databaseId: MigrationConfig.localDatabaseId,
    );

    print('✅ ${collectionsResponse.total} collections trouvées\n');
    print('═══════════════════════════════════════════════════════\n');

    for (var collection in collectionsResponse.collections) {
      print('📦 ${collection.name}');
      print('   ID: ${collection.$id}');

      final collectionData = {
        'id': collection.$id,
        'name': collection.name,
        'enabled': collection.enabled,
        'documentSecurity': collection.documentSecurity,
        'permissions': collection.$permissions,
        'attributes': <Map<String, dynamic>>[],
        'indexes': <Map<String, dynamic>>[],
        'documentCount': 0,
      };

      // Compter les documents
      try {
        final docs = await databases.listDocuments(
          databaseId: MigrationConfig.localDatabaseId,
          collectionId: collection.$id,
        );
        collectionData['documentCount'] = docs.total;
        print('   📄 Documents: ${docs.total}');
      } catch (e) {
        print('   ⚠️ Impossible de compter les documents');
      }

      // Attributs
      print('   📝 Attributs:');
      for (var attr in collection.attributes) {
        final attrData = {
          'key': attr['key'],
          'type': attr['type'],
          'status': attr['status'],
          'required': attr['required'] ?? false,
          'array': attr['array'] ?? false,
          'size': attr['size'],
          'default': attr['default'],
        };

        // Attributs spécifiques selon le type
        if (attr['type'] == 'string' && attr['format'] != null) {
          attrData['format'] = attr['format'];
        }
        if (attr['type'] == 'integer' || attr['type'] == 'double') {
          attrData['min'] = attr['min'];
          attrData['max'] = attr['max'];
        }
        if (attr['type'] == 'relationship') {
          attrData['relatedCollection'] = attr['relatedCollection'];
          attrData['relationType'] = attr['relationType'];
          attrData['twoWay'] = attr['twoWay'];
          attrData['twoWayKey'] = attr['twoWayKey'];
        }

        collectionData['attributes'].add(attrData);

        final required = attr['required'] == true ? ' *' : '';
        final array = attr['array'] == true ? '[]' : '';
        print('      - ${attr['key']}: ${attr['type']}$array$required');
      }

      // Index
      print('   🔍 Index:');
      for (var index in collection.indexes) {
        final indexData = {
          'key': index['key'],
          'type': index['type'],
          'status': index['status'],
          'attributes': index['attributes'],
          'orders': index['orders'],
        };

        collectionData['indexes'].add(indexData);
        print('      - ${index['key']} (${index['type']}): ${index['attributes']}');
      }

      structure['collections'].add(collectionData);
      print('');
    }

    // ═══════════════════════════════════════════════════════
    // 2. ANALYSER LES BUCKETS
    // ═══════════════════════════════════════════════════════
    print('═══════════════════════════════════════════════════════');
    print('🗄️ Analyse des buckets de stockage...\n');

    try {
      final bucketsResponse = await storage.listBuckets();
      print('✅ ${bucketsResponse.total} buckets trouvés\n');

      for (var bucket in bucketsResponse.buckets) {
        print('🗄️ ${bucket.name}');
        print('   ID: ${bucket.$id}');

        final bucketData = {
          'id': bucket.$id,
          'name': bucket.name,
          'enabled': bucket.enabled,
          'permissions': bucket.$permissions,
          'maximumFileSize': bucket.maximumFileSize,
          'allowedFileExtensions': bucket.allowedFileExtensions,
          'compression': bucket.compression,
          'encryption': bucket.encryption,
          'antivirus': bucket.antivirus,
          'fileCount': 0,
        };

        // Compter les fichiers
        try {
          final files = await storage.listFiles(bucketId: bucket.$id);
          bucketData['fileCount'] = files.total;
          print('   📁 Fichiers: ${files.total}');
        } catch (e) {
          print('   ⚠️ Impossible de compter les fichiers');
        }

        print('   📏 Taille max: ${bucket.maximumFileSize} bytes');
        print('   📎 Extensions: ${bucket.allowedFileExtensions}');

        structure['buckets'].add(bucketData);
        print('');
      }
    } catch (e) {
      print('⚠️ Erreur lors de l\'analyse des buckets: $e');
    }

    // ═══════════════════════════════════════════════════════
    // 3. SAUVEGARDER LE RAPPORT
    // ═══════════════════════════════════════════════════════
    print('═══════════════════════════════════════════════════════');
    print('💾 Sauvegarde du rapport...\n');

    final reportFile = File('appwrite_structure_report.json');
    await reportFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(structure),
    );

    print('✅ Rapport sauvegardé: ${reportFile.absolute.path}');

    // ═══════════════════════════════════════════════════════
    // 4. GÉNÉRER LES INSTRUCTIONS DE MIGRATION
    // ═══════════════════════════════════════════════════════
    print('\n📝 Génération des instructions...\n');
    await _generateInstructions(structure);

    // ═══════════════════════════════════════════════════════
    // 5. RÉSUMÉ
    // ═══════════════════════════════════════════════════════
    print('\n═══════════════════════════════════════════════════════');
    print('✅ ANALYSE TERMINÉE !');
    print('═══════════════════════════════════════════════════════');
    print('\n📊 Résumé:');
    print('   Collections: ${structure['collections'].length}');

    int totalDocs = 0;
    for (var col in structure['collections']) {
      totalDocs += (col['documentCount'] as int?) ?? 0;
    }
    print('   Documents: $totalDocs');

    print('   Buckets: ${structure['buckets'].length}');

    int totalFiles = 0;
    for (var bucket in structure['buckets']) {
      totalFiles += (bucket['fileCount'] as int?) ?? 0;
    }
    print('   Fichiers: $totalFiles');

    print('\n📋 Prochaines étapes:');
    print('   1. Lisez le fichier: migration_instructions.md');
    print('   2. Créez la database dans Appwrite Cloud');
    print('   3. Lancez: dart run scripts/2_create_structure.dart');
    print('   4. Lancez: dart run scripts/3_migrate_data.dart');

  } catch (e, stackTrace) {
    print('\n❌ ERREUR: $e');
    print('Stack trace: $stackTrace');
    print('\n⚠️ Vérifiez que:');
    print('  1. Appwrite local est démarré (http://localhost)');
    print('  2. L\'API Key est valide et a les bonnes permissions');
  }
}

Future<void> _generateInstructions(Map<String, dynamic> structure) async {
  final buffer = StringBuffer();

  buffer.writeln('# 🚀 Instructions de migration vers Appwrite Cloud');
  buffer.writeln('');
  buffer.writeln('## ✅ Étape 1 : Créer la database dans Appwrite Cloud');
  buffer.writeln('');
  buffer.writeln('1. Connectez-vous à https://cloud.appwrite.io');
  buffer.writeln('2. Sélectionnez votre projet (ID: ${MigrationConfig.cloudProjectId})');
  buffer.writeln('3. Allez dans **Databases**');
  buffer.writeln('4. Cliquez sur **Create Database**');
  buffer.writeln('5. Nom: `dating_app_production`');
  buffer.writeln('6. **COPIEZ LE DATABASE ID généré**');
  buffer.writeln('7. Mettez à jour `scripts/migration_config.dart` ligne 20 avec ce Database ID');
  buffer.writeln('');
  buffer.writeln('## 📊 Structure à migrer');
  buffer.writeln('');
  buffer.writeln('### Collections (${structure['collections'].length})');
  buffer.writeln('');

  for (var collection in structure['collections']) {
    buffer.writeln('#### ${collection['name']}');
    buffer.writeln('- Documents: ${collection['documentCount']}');
    buffer.writeln('- Attributs: ${collection['attributes'].length}');
    buffer.writeln('- Index: ${collection['indexes'].length}');
    buffer.writeln('');
  }

  buffer.writeln('### Buckets (${structure['buckets'].length})');
  buffer.writeln('');

  for (var bucket in structure['buckets']) {
    buffer.writeln('#### ${bucket['name']}');
    buffer.writeln('- Fichiers: ${bucket['fileCount']}');
    buffer.writeln('- Taille max: ${bucket['maximumFileSize']} bytes');
    buffer.writeln('');
  }

  buffer.writeln('## 🎯 Prochaines étapes');
  buffer.writeln('');
  buffer.writeln('Après avoir créé la database dans le Cloud:');
  buffer.writeln('');
  buffer.writeln('```bash');
  buffer.writeln('# Créer la structure (collections, attributs, index, buckets)');
  buffer.writeln('dart run scripts/2_create_structure.dart');
  buffer.writeln('');
  buffer.writeln('# Migrer les données (documents et fichiers)');
  buffer.writeln('dart run scripts/3_migrate_data.dart');
  buffer.writeln('```');

  final file = File('migration_instructions.md');
  await file.writeAsString(buffer.toString());
  print('✅ Instructions générées: ${file.absolute.path}');
}
