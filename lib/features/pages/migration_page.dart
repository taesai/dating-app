import 'package:flutter/material.dart';
import '../../core/services/migration_service.dart';
import '../../core/services/migrate_existing_photos.dart';
import '../../core/services/test_photos_collection.dart';
import '../../core/services/simple_photo_test.dart';

/// Page temporaire pour lancer les migrations
class MigrationPage extends StatefulWidget {
  const MigrationPage({super.key});

  @override
  State<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends State<MigrationPage> {
  bool _isRunning = false;
  String _status = 'Prêt à migrer';
  Map<String, int>? _result;
  String _migrationType = 'matches'; // 'matches', 'photos', ou 'test'

  Future<void> _runTest() async {
    setState(() {
      _isRunning = true;
      _status = 'Diagnostic en cours... (voir console F12)';
    });

    try {
      // Lancer le nouveau diagnostic complet
      await SimplePhotoTest.runDiagnostic();

      setState(() {
        _isRunning = false;
        _status = '✅ Diagnostic terminé ! Vérifiez la console (F12) pour les résultats détaillés';
      });
    } catch (e) {
      setState(() {
        _isRunning = false;
        _status = '❌ Diagnostic échoué: $e\nVérifiez la console (F12)';
      });
    }
  }

  Future<void> _runMigration() async {
    setState(() {
      _isRunning = true;
      _status = 'Migration en cours...';
      _result = null;
    });

    try {
      final result = _migrationType == 'matches'
          ? await MigrationService.migrateMatchLastMessages()
          : await MigrateExistingPhotos.migrateAllPhotos();

      setState(() {
        _isRunning = false;
        _status = 'Migration terminée!';
        _result = result;
      });
    } catch (e) {
      setState(() {
        _isRunning = false;
        _status = 'Erreur: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Migrations'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sync,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              Text(
                _status,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isRunning)
                const CircularProgressIndicator()
              else if (_result == null) ...[
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'matches',
                      label: Text('Matches'),
                      icon: Icon(Icons.favorite),
                    ),
                    ButtonSegment(
                      value: 'photos',
                      label: Text('Photos'),
                      icon: Icon(Icons.photo),
                    ),
                  ],
                  selected: {_migrationType},
                  onSelectionChanged: (Set<String> selected) {
                    setState(() => _migrationType = selected.first);
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _runTest,
                  icon: const Icon(Icons.bug_report),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  label: const Text(
                    'Diagnostic Photos',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _runMigration,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  ),
                  child: Text(
                    _migrationType == 'matches'
                        ? 'Migrer les messages'
                        : 'Migrer les photos',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ]
              else
                Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _migrationType == 'matches'
                              ? [
                                  Text(
                                    '✅ Matches mis à jour: ${_result!['updated']}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ℹ️ Matches ignorés: ${_result!['skipped']}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '❌ Erreurs: ${_result!['errors']}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ]
                              : [
                                  Text(
                                    '✅ Photos créées: ${_result!['photosCreated']}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '👤 Utilisateurs traités: ${_result!['usersProcessed']}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '❌ Erreurs: ${_result!['errors']}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Retour'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
