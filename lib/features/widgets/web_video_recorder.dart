import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;

class WebVideoRecorder extends StatefulWidget {
  final int maxDurationSeconds;

  const WebVideoRecorder({
    super.key,
    required this.maxDurationSeconds,
  });

  @override
  State<WebVideoRecorder> createState() => _WebVideoRecorderState();
}

class _WebVideoRecorderState extends State<WebVideoRecorder> {
  html.MediaStream? _mediaStream;
  html.MediaRecorder? _mediaRecorder;
  final List<html.Blob> _recordedChunks = [];
  bool _isRecording = false;
  bool _isPaused = false;
  bool _hasRecorded = false;
  int _recordedSeconds = 0;
  Timer? _timer;
  Uint8List? _recordedBytes;
  String? _recordedFilename;
  final String _videoElementId = 'video-preview-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _stopRecording();
    _stopCamera();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      print('🎥 Demande d\'accès à la caméra...');

      final constraints = {
        'video': {
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
          'facingMode': 'user',
        },
        'audio': true,
      };

      _mediaStream = await html.window.navigator.mediaDevices!.getUserMedia(constraints);

      print('✅ Accès caméra accordé!');

      // Créer l'élément vidéo
      final videoElement = html.VideoElement()
        ..id = _videoElementId
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      videoElement.srcObject = _mediaStream;

      // Enregistrer la vue
      ui_web.platformViewRegistry.registerViewFactory(
        _videoElementId,
        (int viewId) => videoElement,
      );

      if (mounted) setState(() {});
    } catch (e) {
      print('❌ Erreur accès caméra: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'accès à la caméra: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startRecording() {
    if (_mediaStream == null) return;

    try {
      print('🔴 Démarrage de l\'enregistrement...');

      _recordedChunks.clear();
      _recordedSeconds = 0;

      // Créer le MediaRecorder
      _mediaRecorder = html.MediaRecorder(_mediaStream!, {
        'mimeType': 'video/webm;codecs=vp9',
      });

      // Écouter les données
      _mediaRecorder!.addEventListener('dataavailable', (event) {
        final html.BlobEvent blobEvent = event as html.BlobEvent;
        if (blobEvent.data != null && blobEvent.data!.size > 0) {
          _recordedChunks.add(blobEvent.data!);
        }
      });

      // Écouter la fin
      _mediaRecorder!.addEventListener('stop', (event) {
        _processRecording();
      });

      _mediaRecorder!.start();

      setState(() {
        _isRecording = true;
      });

      // Timer pour compter les secondes et arrêter automatiquement
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordedSeconds++;
        });

        if (_recordedSeconds >= widget.maxDurationSeconds) {
          _stopRecording();
        }
      });

      print('✅ Enregistrement démarré');
    } catch (e) {
      print('❌ Erreur démarrage enregistrement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'enregistrement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopRecording() {
    if (_mediaRecorder != null && _isRecording) {
      print('⏹️ Arrêt de l\'enregistrement...');
      _mediaRecorder!.stop();
      _timer?.cancel();
      setState(() {
        _isRecording = false;
      });
    }
  }

  void _stopCamera() {
    if (_mediaStream != null) {
      _mediaStream!.getTracks().forEach((track) {
        track.stop();
      });
      _mediaStream = null;
    }
  }

  Future<void> _processRecording() async {
    if (_recordedChunks.isEmpty) {
      print('⚠️ Aucune donnée enregistrée');
      return;
    }

    try {
      print('🎬 Traitement de la vidéo...');

      // Créer un blob avec toutes les données
      final blob = html.Blob(_recordedChunks, 'video/webm');

      // Lire le blob en bytes
      final reader = html.FileReader();
      reader.readAsArrayBuffer(blob);

      await reader.onLoad.first;

      final Uint8List bytes = reader.result as Uint8List;
      final filename = 'video_${DateTime.now().millisecondsSinceEpoch}.webm';

      print('✅ Vidéo traitée: ${bytes.length} bytes');

      // Stocker les données et afficher le bouton de confirmation
      setState(() {
        _recordedBytes = bytes;
        _recordedFilename = filename;
        _hasRecorded = true;
      });
    } catch (e) {
      print('❌ Erreur traitement vidéo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de traitement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _useRecordedVideo() {
    if (_recordedBytes != null && _recordedFilename != null) {
      // Retourner les données via Navigator.pop
      Navigator.pop(context, {
        'bytes': _recordedBytes!,
        'filename': _recordedFilename!,
      });
    }
  }

  void _retakeVideo() {
    setState(() {
      _hasRecorded = false;
      _recordedBytes = null;
      _recordedFilename = null;
      _recordedChunks.clear();
      _recordedSeconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isRecording
              ? 'Enregistrement: $_recordedSeconds / ${widget.maxDurationSeconds}s'
              : 'Caméra prête',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Aperçu de la caméra
          if (_mediaStream != null)
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: HtmlElementView(viewType: _videoElementId),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Contrôles
          if (_mediaStream != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: _hasRecorded
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _retakeVideo,
                            icon: const Icon(Icons.replay),
                            label: const Text('Réenregistrer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _useRecordedVideo,
                            icon: const Icon(Icons.check),
                            label: const Text('Utiliser cette vidéo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_isRecording)
                            FloatingActionButton(
                              onPressed: _startRecording,
                              backgroundColor: Colors.red,
                              child: const Icon(Icons.fiber_manual_record, size: 36),
                            )
                          else
                            FloatingActionButton(
                              onPressed: _stopRecording,
                              backgroundColor: Colors.white,
                              child: const Icon(Icons.stop, color: Colors.red, size: 36),
                            ),
                        ],
                      ),
              ),
            ),

          // Timer et durée max
          if (_isRecording)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_recordedSeconds / ${widget.maxDurationSeconds}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
