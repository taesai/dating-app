import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/services/appwrite_service.dart';
import '../../core/models/video_model.dart';
import '../../core/models/dating_user.dart';
import 'photo_moderation_widget.dart';

class ContentModerationPage extends StatefulWidget {
  const ContentModerationPage({super.key});

  @override
  State<ContentModerationPage> createState() => _ContentModerationPageState();
}

class _ContentModerationPageState extends State<ContentModerationPage> with SingleTickerProviderStateMixin {
  final AppwriteService _appwriteService = AppwriteService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.deepPurple,
              tabs: const [
                Tab(icon: Icon(Icons.video_library), text: 'Vidéos'),
                Tab(icon: Icon(Icons.photo_library), text: 'Photos'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _VideoModerationTab(),
                PhotoModerationWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Tab de modération des vidéos
class _VideoModerationTab extends StatefulWidget {
  const _VideoModerationTab();

  @override
  State<_VideoModerationTab> createState() => _VideoModerationTabState();
}

class _VideoModerationTabState extends State<_VideoModerationTab> {
  final AppwriteService _appwriteService = AppwriteService();
  List<VideoModel> _pendingVideos = [];
  Map<String, DatingUser> _videoUsers = {};
  bool _isLoading = true;
  String _filter = 'pending'; // pending, approved, rejected, all

  @override
  void initState() {
    super.initState();
    _loadPendingVideos();
  }

  Future<void> _loadPendingVideos() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer toutes les vidéos (admin - sans filtre isApproved)
      final response = await _appwriteService.getAllVideosForAdmin(limit: 100);
      final allVideos = (response.documents as List)
          .map((doc) => VideoModel.fromJson(doc.data))
          .toList();

      // Filtrer selon le statut sélectionné
      List<VideoModel> filteredVideos;
      switch (_filter) {
        case 'pending':
          filteredVideos = allVideos.where((v) => !v.isApproved).toList();
          break;
        case 'approved':
          filteredVideos = allVideos.where((v) => v.isApproved).toList();
          break;
        case 'rejected':
          // Pour l'instant, pas de statut rejeté distinct
          filteredVideos = [];
          break;
        case 'all':
        default:
          filteredVideos = allVideos;
      }

      // Charger les infos des utilisateurs
      for (var video in filteredVideos) {
        try {
          final userDoc = await _appwriteService.getUserProfile(video.userId);
          _videoUsers[video.userId] = DatingUser.fromJson(userDoc.data);
        } catch (e) {
          print('Erreur chargement user: $e');
        }
      }

      setState(() {
        _pendingVideos = filteredVideos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtres - TOUJOURS VISIBLES
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              _buildFilterChip('En attente', 'pending', Icons.pending),
              const SizedBox(width: 8),
              _buildFilterChip('Approuvées', 'approved', Icons.check_circle),
              const SizedBox(width: 8),
              _buildFilterChip('Rejetées', 'rejected', Icons.cancel),
              const SizedBox(width: 8),
              _buildFilterChip('Toutes', 'all', Icons.all_inclusive),
            ],
          ),
        ),

        // Contenu
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pendingVideos.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: _pendingVideos.length,
            itemBuilder: (context, index) {
              final video = _pendingVideos[index];
              final user = _videoUsers[video.userId];

              return _VideoCard(
                video: video,
                user: user,
                onApprove: () => _handleApprove(video),
                onReject: () => _handleReject(video),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    Color? iconColor;

    switch (_filter) {
      case 'pending':
        message = 'Aucune vidéo en attente de modération';
        icon = Icons.check_circle;
        iconColor = Colors.green[300];
        break;
      case 'approved':
        message = 'Aucune vidéo approuvée';
        icon = Icons.video_library_outlined;
        iconColor = Colors.grey[300];
        break;
      case 'rejected':
        message = 'Aucune vidéo rejetée';
        icon = Icons.block;
        iconColor = Colors.grey[300];
        break;
      case 'all':
      default:
        message = 'Aucune vidéo disponible';
        icon = Icons.videocam_off;
        iconColor = Colors.grey[300];
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: iconColor),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filter = value);
        _loadPendingVideos();
      },
      selectedColor: Colors.deepPurple,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }

  Future<void> _handleApprove(VideoModel video) async {
    try {
      print('🟢 ADMIN: Approbation de la vidéo ${video.id} (user: ${video.userId})...');

      await _appwriteService.approveVideo(video.id);

      print('✅ ADMIN: Vidéo approuvée avec succès');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vidéo approuvée'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPendingVideos();
      }
    } catch (e) {
      print('❌ ADMIN: Erreur lors de l approbation de la vidéo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(VideoModel video) async {
    final reason = await _showRejectDialog();
    if (reason == null) return;

    try {
      await _appwriteService.rejectVideo(video.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vidéo rejetée: $reason'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadPendingVideos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showRejectDialog() async {
    String? selectedReason;
    final reasons = [
      'Contenu inapproprié',
      'Nudité ou contenu sexuel',
      'Violence ou contenu choquant',
      'Spam ou publicité',
      'Violation des droits d\'auteur',
      'Autre',
    ];

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raison du rejet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: reasons.map((reason) {
            return RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: selectedReason,
              onChanged: (value) {
                selectedReason = value;
                Navigator.pop(context, value);
              },
            );
          }).toList(),
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
}

// Card pour une vidéo en modération
class _VideoCard extends StatefulWidget {
  final VideoModel video;
  final DatingUser? user;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _VideoCard({
    required this.video,
    required this.user,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    final videoUrl = AppwriteService().getVideoUrl(widget.video.fileId);
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller != null && _isInitialized) {
      if (_isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
        _controller!.setLooping(true);
      }
      setState(() => _isPlaying = !_isPlaying);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vidéo preview avec thumbnail
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_controller != null && _controller!.value.isInitialized)
                  VideoPlayer(_controller!)
                else
                  // Afficher un placeholder avec icône vidéo
                  Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.play_circle_outline, size: 80, color: Colors.white70),
                  ),

                // Overlay avec gradient et bouton play
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _togglePlay,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info utilisateur
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: widget.user?.photoUrlsFull.isNotEmpty ?? false
                          ? NetworkImage(widget.user!.photoUrlsFull.first)
                          : null,
                      child: widget.user?.photoUrlsFull.isEmpty ?? true
                          ? const Icon(Icons.person, size: 12)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.user?.name ?? 'Utilisateur',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.video.title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.favorite, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text('${widget.video.likes}', style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(widget.video.createdAt),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: widget.onReject,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Rejeter'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey[300]),
              Expanded(
                child: TextButton.icon(
                  onPressed: widget.onApprove,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approuver'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays}j';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inMinutes}m';
    }
  }
}

// Tab de modération des photos
class _PhotoModerationTab extends StatefulWidget {
  const _PhotoModerationTab();

  @override
  State<_PhotoModerationTab> createState() => _PhotoModerationTabState();
}

class _PhotoModerationTabState extends State<_PhotoModerationTab> {
  final AppwriteService _appwriteService = AppwriteService();
  List<Map<String, dynamic>> _pendingPhotos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingPhotos();
  }

  Future<void> _loadPendingPhotos() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Implémenter récupération des photos en attente
      // Pour l'instant, simuler avec des données vides
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _pendingPhotos = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Modération des photos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune photo en attente de modération',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          const Text(
            '💡 Les photos seront modérées ici',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
