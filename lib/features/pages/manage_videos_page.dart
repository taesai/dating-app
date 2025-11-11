import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/dating_user.dart';
import '../../core/models/video_model.dart';
import '../../core/services/backend_service.dart';
import '../../core/services/video_compression_service.dart';


class ManageVideosPage extends StatefulWidget {
  final DatingUser currentUser;

  const ManageVideosPage({super.key, required this.currentUser});

  @override
  State<ManageVideosPage> createState() => _ManageVideosPageState();
}

class _ManageVideosPageState extends State<ManageVideosPage> {
  final BackendService _backend = BackendService();
  final ImagePicker _picker = ImagePicker();
  final VideoCompressionService _compressionService = VideoCompressionService();
  bool _isUploading = false;
  bool _isCompressing = false;
  double _compressionProgress = 0.0;
  List<VideoModel> _videos = [];
  Map<String, VideoPlayerController> _controllers = {};

  // Limite de vidéos selon le plan d'abonnement
  int get _maxVideos {
    return widget.currentUser.effectivePlan == 'free' ? 2 : 10;
  }

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    // Libérer tous les contrôleurs vidéo
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadVideos() async {
    try {
      print('🎬 Chargement des vidéos...');

      final videosResponse = await _backend.getUserVideos(widget.currentUser.id);
      final videosList = videosResponse.documents as List;

      final videos = videosList.map((doc) {
        final data = doc is Map ? doc : doc.data;
        return VideoModel.fromJson(data);
      }).toList();

      print('✅ ${videos.length} vidéos chargées');

      if (mounted) {
        setState(() {
          _videos = videos;
        });

        // Initialiser les contrôleurs pour les vidéos
        for (var video in videos) {
          _initVideoController(video);
        }
      }
    } catch (e, stackTrace) {
      print('❌ Erreur chargement vidéos: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _initVideoController(VideoModel video) {
    final videoUrl = _backend.getVideoUrl(video.fileId);
    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _controllers[video.id] = controller;
        });
      }
    }).catchError((error) {
      print('❌ Erreur init contrôleur vidéo ${video.id}: $error');
    });
  }

  Future<void> _pickAndUploadVideo() async {
    // Vérifier la limite de vidéos
    if (_videos.length >= _maxVideos) {
      if (mounted) {
        final replace = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Limite atteinte'),
            content: Text(
              'Vous avez atteint la limite de $_maxVideos vidéos en mode ${widget.currentUser.effectivePlan == 'free' ? "gratuit" : "premium"}.\n\nSouhaitez-vous remplacer une vidéo existante ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Choisir une vidéo à remplacer'),
              ),
            ],
          ),
        );

        if (replace != true) return;

        // Demander quelle vidéo remplacer
        final videoToReplace = await _selectVideoToReplace();
        if (videoToReplace == null) return;

        // Supprimer l'ancienne vidéo
        await _backend.deleteVideo(videoToReplace.id);
      } else {
        return;
      }
    }

    try {
      print('🎬 Sélection de la vidéo...');
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: Duration(seconds: widget.currentUser.planLimits.maxVideoDurationSeconds),
      );

      if (video == null) {
        print('❌ Aucune vidéo sélectionnée');
        return;
      }

      print('✅ Vidéo sélectionnée: ${video.name}');

      // Vérifier si la compression est nécessaire
      final needsCompression = await _compressionService.needsCompression(video);

      Uint8List finalBytes;
      String finalFileName;

      if (needsCompression) {
        setState(() {
          _isCompressing = true;
          _compressionProgress = 0.0;
        });

        print('🔄 Compression de la vidéo...');
        final compressed = await _compressionService.compressVideo(
          videoFile: video,
          quality: VideoQuality.high,
        );

        print('✅ $compressed');

        finalBytes = compressed.bytes;
        finalFileName = compressed.fileName;

        setState(() {
          _isCompressing = false;
          _compressionProgress = 1.0;
        });
      } else {
        print('⏭️ Compression non nécessaire');
        finalBytes = await video.readAsBytes();
        finalFileName = video.name;
      }

      setState(() => _isUploading = true);

      print('🚀 Upload vers backend...');
      await _backend.uploadVideo(
        userId: widget.currentUser.id,
        filePath: '', // Pas utilisé pour backend local
        title: 'Ma vidéo',
        fileBytes: finalBytes,
        fileName: finalFileName,
      );

      print('✅ Upload terminé !');
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadVideos();

      setState(() => _isUploading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vidéo ajoutée ! Total: ${_videos.length}/$_maxVideos'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur upload: $e');
      setState(() {
        _isUploading = false;
        _isCompressing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<VideoModel?> _selectVideoToReplace() async {
    return await showDialog<VideoModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une vidéo à remplacer'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _videos.length,
            itemBuilder: (context, index) {
              final video = _videos[index];
              final controller = _controllers[video.id];
              final isMain = index == 0;

              return Card(
                child: ListTile(
                  leading: SizedBox(
                    width: 60,
                    height: 60,
                    child: controller != null && controller.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: VideoPlayer(controller),
                          )
                        : const Icon(Icons.video_library, size: 40),
                  ),
                  title: Text(video.title.isEmpty ? 'Vidéo ${index + 1}' : video.title),
                  subtitle: isMain ? const Text('Principale', style: TextStyle(color: Colors.pink)) : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, video),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _setAsMainVideo(VideoModel video) async {
    try {
      // Réorganiser les vidéos pour mettre celle-ci en premier
      final videoIndex = _videos.indexOf(video);
      if (videoIndex == -1) return;

      final reorderedVideos = List<VideoModel>.from(_videos);
      reorderedVideos.removeAt(videoIndex);
      reorderedVideos.insert(0, video);

      // Mettre à jour l'ordre dans le backend
      final videoIds = reorderedVideos.map((v) => v.id).toList();
      await _backend.updateUserProfile(
        userId: widget.currentUser.id,
        data: {'videoIds': videoIds},
      );

      await _loadVideos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vidéo principale mise à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur mise à jour vidéo principale: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteVideo(VideoModel video) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette vidéo ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Libérer le contrôleur avant suppression
      _controllers[video.id]?.dispose();
      _controllers.remove(video.id);

      await _backend.deleteVideo(video.id);
      await _loadVideos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vidéo supprimée'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur suppression: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.pink,
          title: const Text('Gérer mes vidéos', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
        body: _isCompressing || _isUploading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _isCompressing ? 'Compression de la vidéo...' : 'Upload en cours...',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    if (_isCompressing && _compressionProgress > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                        child: LinearProgressIndicator(value: _compressionProgress),
                      ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info sur la limite
                    Card(
                      color: Colors.pink.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.pink.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_videos.length}/$_maxVideos vidéos • ${widget.currentUser.effectivePlan == 'free' ? "Mode gratuit (2 vidéos max)" : "Mode premium (10 vidéos max)"}',
                                style: TextStyle(
                                  color: Colors.pink.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bouton ajouter
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _pickAndUploadVideo,
                        icon: const Icon(Icons.video_call),
                        label: const Text('Ajouter une vidéo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Message si aucune vidéo
                    if (_videos.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.video_library_outlined, size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune vidéo',
                                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ajoutez des vidéos pour rendre votre profil plus dynamique',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Liste de vidéos
                    if (_videos.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _videos.length,
                        itemBuilder: (context, index) {
                          final video = _videos[index];
                          final controller = _controllers[video.id];
                          final isMain = index == 0;

                          return Card(
                            clipBehavior: Clip.antiAlias,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isMain
                                  ? const BorderSide(color: Colors.pink, width: 3)
                                  : BorderSide.none,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Vidéo preview
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Container(
                                    color: Colors.black,
                                    child: controller != null && controller.value.isInitialized
                                        ? Stack(
                                            children: [
                                              VideoPlayer(controller),
                                              Center(
                                                child: Icon(
                                                  Icons.play_circle_outline,
                                                  size: 60,
                                                  color: Colors.white.withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Center(
                                            child: CircularProgressIndicator(color: Colors.white),
                                          ),
                                  ),
                                ),

                                // Informations et actions
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (isMain) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.pink,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.star, color: Colors.white, size: 14),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Principale',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Expanded(
                                            child: Text(
                                              video.title.isEmpty ? 'Vidéo ${index + 1}' : video.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Stats de la vidéo
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            Column(
                                              children: [
                                                Icon(Icons.visibility, size: 20, color: Colors.blue),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${video.views}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  'Vues',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              children: [
                                                Icon(Icons.favorite, size: 20, color: Colors.red),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${video.likes}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  'Likes',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          if (!isMain)
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                icon: const Icon(Icons.star_outline, size: 18),
                                                label: const Text('Principale'),
                                                onPressed: () => _setAsMainVideo(video),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.pink,
                                                ),
                                              ),
                                            ),
                                          if (!isMain) const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              icon: const Icon(Icons.delete, size: 18),
                                              label: const Text('Supprimer'),
                                              onPressed: () => _deleteVideo(video),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
