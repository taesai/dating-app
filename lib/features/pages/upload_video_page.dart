import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/services/backend_service.dart';
import '../../core/services/compression_service.dart';
import '../../core/models/dating_user.dart';
import '../widgets/web_video_recorder.dart' if (dart.library.io) '../widgets/web_video_recorder_stub.dart';

class UploadVideoPage extends StatefulWidget {
  final DatingUser currentUser;

  const UploadVideoPage({super.key, required this.currentUser});

  @override
  State<UploadVideoPage> createState() => _UploadVideoPageState();
}

class _UploadVideoPageState extends State<UploadVideoPage> {
  final BackendService _backend = BackendService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  XFile? _videoFile;
  Uint8List? _webVideoBytes;
  String? _webVideoFileName;
  html.File? _htmlVideoFile; // Pour l'analyse avec CompressionService
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  Map<String, dynamic>? _videoAnalysis; // Analyse de la vidéo (taille, durée, etc.)

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        // Vérifier la durée
        final isValid = await _validateVideoDuration(video);
        if (!isValid) return;

        setState(() {
          _videoFile = video;
        });

        // Sur Web, charger aussi les bytes pour l'upload
        if (kIsWeb) {
          print('🌐 Mode Web détecté, chargement des bytes...');
          final bytes = await video.readAsBytes();
          print('✅ Bytes chargés: ${bytes.length} bytes');

          setState(() {
            _webVideoBytes = bytes;
            _webVideoFileName = video.name;
          });

          print('✅ État mis à jour: _webVideoBytes=${_webVideoBytes?.length}, _webVideoFileName=$_webVideoFileName');

          // Analyser la vidéo
          await _analyzeVideoFile(video);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection de la vidéo: $e')),
        );
      }
    }
  }

  /// Analyser un fichier vidéo (taille, durée, résolution)
  Future<void> _analyzeVideoFile(XFile video) async {
    try {
      if (!kIsWeb) return;

      print('🔍 Analyse de la vidéo...');

      // Créer un html.File depuis XFile pour l'analyse
      final bytes = await video.readAsBytes();
      final blob = html.Blob([bytes], 'video/mp4');
      final htmlFile = html.File([blob], video.name, {'type': 'video/mp4'});

      setState(() {
        _htmlVideoFile = htmlFile;
      });

      // Analyser avec le service de compression
      final analysis = await CompressionService.analyzeVideo(videoFile: htmlFile);

      setState(() {
        _videoAnalysis = analysis;
      });

      // Afficher un avertissement si la vidéo est trop volumineuse
      if (analysis['isTooBig'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(analysis['recommendation'] ?? 'Vidéo trop volumineuse'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      print('✅ Analyse terminée: ${analysis['sizeMB']} MB, ${analysis['duration']}s');
    } catch (e) {
      print('❌ Erreur analyse vidéo: $e');
    }
  }

  Future<void> _recordVideo() async {
    try {
      if (kIsWeb) {
        // Sur le web, utiliser notre widget personnalisé avec la webcam
        print('🌐 Ouverture de l\'enregistrement webcam...');
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => WebVideoRecorder(
              maxDurationSeconds: widget.currentUser.planLimits.maxVideoDurationSeconds,
            ),
          ),
        );

        // Récupérer les données après la fermeture de la page
        print('🔍 Résultat reçu: $result');
        if (result != null && result.containsKey('bytes') && result.containsKey('filename')) {
          setState(() {
            _webVideoBytes = result['bytes'] as Uint8List;
            _webVideoFileName = result['filename'] as String;
          });
          print('✅ Vidéo enregistrée: ${_webVideoBytes!.length} bytes, nom: $_webVideoFileName');
        } else {
          print('⚠️ Aucune vidéo reçue ou données incomplètes');
        }
      } else {
        // Sur mobile, utiliser image_picker
        final XFile? video = await _picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: Duration(seconds: widget.currentUser.planLimits.maxVideoDurationSeconds),
        );

        if (video != null) {
          final isValid = await _validateVideoDuration(video);
          if (!isValid) return;

          setState(() {
            _videoFile = video;
          });
        }
      }
    } catch (e) {
      print('❌ Erreur enregistrement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
        );
      }
    }
  }

  Future<bool> _validateVideoDuration(XFile video) async {
    try {
      print('🎬 Validation de la durée de la vidéo...');

      final VideoPlayerController controller;

      if (kIsWeb) {
        // Sur le web, créer un Blob URL
        final bytes = await video.readAsBytes();
        final blob = Uri.dataFromBytes(bytes, mimeType: 'video/mp4');
        controller = VideoPlayerController.networkUrl(blob);
      } else {
        controller = VideoPlayerController.file(File(video.path));
      }

      await controller.initialize();
      final durationInSeconds = controller.value.duration.inSeconds;
      controller.dispose();

      print('⏱️ Durée: $durationInSeconds s / Max: ${widget.currentUser.planLimits.maxVideoDurationSeconds} s');

      if (durationInSeconds > widget.currentUser.planLimits.maxVideoDurationSeconds) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Vidéo trop longue! Maximum: ${widget.currentUser.planLimits.maxVideoDurationSeconds}s (Durée: ${durationInSeconds}s)',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return false;
      }

      return true;
    } catch (e) {
      print('⚠️ Erreur validation durée: $e');
      // En cas d'erreur, autoriser (pour ne pas bloquer)
      return true;
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null && _webVideoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner ou enregistrer une vidéo')),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un titre')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      print('🚀 Début de l\'upload...');

      // Déterminer les bytes et le nom de fichier
      final Uint8List bytes;
      final String fileName;

      if (_webVideoBytes != null) {
        // Vidéo enregistrée avec webcam
        bytes = _webVideoBytes!;
        fileName = _webVideoFileName!;
        print('🎥 Upload vidéo webcam: ${bytes.length} bytes');
      } else {
        // Vidéo sélectionnée depuis fichier
        bytes = await _videoFile!.readAsBytes();
        fileName = _videoFile!.name;
        print('📦 Upload fichier sélectionné: ${bytes.length} bytes');
      }

      setState(() {
        _uploadProgress = 0.3;
      });

      await _backend.uploadVideo(
        userId: widget.currentUser.id,
        filePath: _videoFile?.path ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        fileBytes: bytes,
        fileName: fileName,
      );

      print('✅ Upload terminé avec succès!');

      setState(() {
        _uploadProgress = 1.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vidéo uploadée avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retourner true pour indiquer le succès
      }
    } catch (e, stackTrace) {
      print('❌ Erreur upload: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxDuration = widget.currentUser.planLimits.maxVideoDurationSeconds;
    final planName = widget.currentUser.planLimits.planName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une vidéo'),
        actions: [
          if ((_videoFile != null || _webVideoBytes != null) && !_isUploading)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _uploadVideo,
            ),
        ],
      ),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Upload en cours...',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: LinearProgressIndicator(value: _uploadProgress),
                  ),
                  const SizedBox(height: 8),
                  Text('${(_uploadProgress * 100).toInt()}%'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Plan info card
                  Card(
                    color: widget.currentUser.effectivePlan == 'gold'
                        ? Colors.amber[50]
                        : widget.currentUser.effectivePlan == 'silver'
                        ? Colors.purple[50]
                        : Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                widget.currentUser.effectivePlan == 'free'
                                    ? Icons.info_outline
                                    : Icons.star,
                                color: widget.currentUser.effectivePlan == 'gold'
                                    ? Colors.amber[700]
                                    : widget.currentUser.effectivePlan == 'silver'
                                    ? Colors.purple[700]
                                    : Colors.blue[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Plan $planName',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: widget.currentUser.effectivePlan == 'gold'
                                      ? Colors.amber[900]
                                      : widget.currentUser.effectivePlan == 'silver'
                                      ? Colors.purple[900]
                                      : Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Durée maximale de vidéo: $maxDuration secondes',
                            style: TextStyle(
                              color: widget.currentUser.effectivePlan == 'gold'
                                  ? Colors.amber[900]
                                  : widget.currentUser.effectivePlan == 'silver'
                                  ? Colors.purple[900]
                                  : Colors.blue[900],
                            ),
                          ),
                          if (widget.currentUser.effectivePlan == 'free') ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                // TODO: Navigation vers la page d'abonnement Premium
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Fonctionnalité Premium à venir!'),
                                  ),
                                );
                              },
                              child: const Text('Passer à Premium pour 10s'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Video preview
                  if (_videoFile != null || _webVideoBytes != null) ...[
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _webVideoBytes != null ? Icons.videocam : Icons.video_library,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _webVideoBytes != null ? 'Vidéo enregistrée' : 'Vidéo sélectionnée',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _webVideoBytes != null ? _webVideoFileName! : _videoFile!.name,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _videoFile = null;
                                  _webVideoBytes = null;
                                  _webVideoFileName = null;
                                  _htmlVideoFile = null;
                                  _videoAnalysis = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Informations sur la vidéo (taille, durée, résolution)
                    if (_videoAnalysis != null && _videoAnalysis!['error'] == null) ...[
                      Card(
                        color: _videoAnalysis!['isTooBig'] == true
                            ? Colors.orange[50]
                            : Colors.green[50],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _videoAnalysis!['isTooBig'] == true
                                        ? Icons.warning_amber
                                        : Icons.check_circle,
                                    color: _videoAnalysis!['isTooBig'] == true
                                        ? Colors.orange[700]
                                        : Colors.green[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Informations vidéo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _videoAnalysis!['isTooBig'] == true
                                            ? Colors.orange[900]
                                            : Colors.green[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('📦 Taille:', style: TextStyle(color: Colors.grey[700])),
                                  Text(
                                    '${_videoAnalysis!['sizeMB']} MB',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _videoAnalysis!['isTooBig'] == true
                                          ? Colors.orange[900]
                                          : Colors.green[900],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('⏱️ Durée:', style: TextStyle(color: Colors.grey[700])),
                                  Text(
                                    '${_videoAnalysis!['duration'].toStringAsFixed(1)}s',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('📐 Résolution:', style: TextStyle(color: Colors.grey[700])),
                                  Text(
                                    '${_videoAnalysis!['width']}x${_videoAnalysis!['height']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                ],
                              ),
                              if (_videoAnalysis!['isTooBig'] == true) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '⚠️ ${_videoAnalysis!['recommendation']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[900],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],

                  // Action buttons
                  if (_videoFile == null && _webVideoBytes == null) ...[
                    // Bouton enregistrer (maintenant disponible sur web avec webcam!)
                    ElevatedButton.icon(
                      onPressed: _recordVideo,
                      icon: const Icon(Icons.videocam),
                      label: Text(kIsWeb
                        ? 'Enregistrer avec ma webcam ($maxDuration s max)'
                        : 'Enregistrer une vidéo ($maxDuration s max)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Bouton choisir depuis la galerie
                    OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.video_library),
                      label: Text(kIsWeb
                        ? 'Ou choisir une vidéo depuis mon ordinateur'
                        : 'Ou choisir depuis la galerie'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],

                  // Video details form
                  if (_videoFile != null || _webVideoBytes != null) ...[
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre de la vidéo *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optionnelle)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _uploadVideo,
                      icon: const Icon(Icons.upload),
                      label: const Text('Publier la vidéo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Tips card
                  Card(
                    color: Colors.purple[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: Colors.purple[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Conseils pour votre vidéo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Présentez-vous avec enthousiasme\n'
                            '• Parlez de vos passions\n'
                            '• Souriez et soyez naturel(le)\n'
                            '• Montrez votre personnalité\n'
                            '• Filmez dans un endroit bien éclairé',
                            style: TextStyle(color: Colors.purple[900]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
