import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/models/dating_user.dart';
import '../../core/models/video_model.dart';
import '../../core/services/backend_service.dart';
import '../widgets/report_user_dialog.dart';

class UserDetailProfilePage extends StatefulWidget {
  final DatingUser user;
  final String? currentUserId;

  const UserDetailProfilePage({
    super.key,
    required this.user,
    this.currentUserId,
  });

  @override
  State<UserDetailProfilePage> createState() => _UserDetailProfilePageState();
}

class _UserDetailProfilePageState extends State<UserDetailProfilePage> {
  final BackendService _backend = BackendService();
  List<VideoModel> _userVideos = [];
  bool _isLoadingVideos = true;
  int _selectedPhotoIndex = 0;
  bool _hasLiked = false; // Pour empêcher les likes multiples

  @override
  void initState() {
    super.initState();
    _loadUserVideos();
  }

  Future<void> _loadUserVideos() async {
    try {
      final List<VideoModel> videos = [];
      for (final videoId in widget.user.videoIds) {
        try {
          final videoDoc = await _backend.getVideoById(videoId);
          final videoData = videoDoc is Map ? videoDoc : videoDoc.data;
          videos.add(VideoModel.fromJson(videoData));
        } catch (e) {
          print('Erreur chargement vidéo $videoId: $e');
        }
      }
      setState(() {
        _userVideos = videos;
        _isLoadingVideos = false;
      });
    } catch (e) {
      setState(() => _isLoadingVideos = false);
    }
  }

  Future<void> _likeUser() async {
    if (widget.currentUserId == null) return;

    // Empêcher les likes multiples
    if (_hasLiked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez déjà liké ce profil'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      // Marquer comme liké avant l'appel pour éviter les doubles clics
      setState(() => _hasLiked = true);

      final match = await _backend.likeUser(
        fromUserId: widget.currentUserId!,
        toUserId: widget.user.id,
      );

      if (match != null && mounted) {
        _showMatchDialog();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.white),
                const SizedBox(width: 8),
                Text('Vous avez liké ${widget.user.name} !'),
              ],
            ),
            backgroundColor: Colors.pink,
          ),
        );
        // Retourner true pour indiquer qu'un like a été effectué
        Navigator.pop(context, true);
      }
    } catch (e) {
      // En cas d'erreur, réinitialiser le flag
      setState(() => _hasLiked = false);

      if (mounted) {
        final errorMsg = e.toString();
        // Si déjà liké, c'est normal - ne pas afficher d'erreur
        if (errorMsg.contains('Déjà liké') || errorMsg.contains('already liked')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous avez déjà liké ce profil'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  void _showMatchDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink[300]!, Colors.purple[300]!],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 80),
              const SizedBox(height: 16),
              const Text(
                'C\'est un Match !',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous et ${widget.user.name} vous aimez mutuellement !',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Fermer le dialog
                        Navigator.pop(context, true); // Retourner à la page précédente avec true
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.pink,
                      ),
                      child: const Text('Continuer'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Fermer le dialog
                        Navigator.pop(context, true); // Retourner à la page précédente avec true
                        // TODO: Naviguer vers les messages
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.pink,
                      ),
                      child: const Text('Message'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playVideo(VideoModel video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _VideoPlayerPage(
          video: video,
          backendService: _backend,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwnProfile = widget.currentUserId == widget.user.id;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Si on swipe vers le bas (velocity positive) OU vers le haut (velocity négative), revenir en arrière
        if (details.primaryVelocity != null &&
            (details.primaryVelocity! > 300 || details.primaryVelocity! < -300)) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: CustomScrollView(
        slivers: [
          // App Bar avec photos
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            actions: [
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.report, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Signaler'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Bloquer'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'report') {
                    showDialog(
                      context: context,
                      builder: (context) => ReportUserDialog(
                        reportedUserId: widget.user.id,
                        reportedUserName: widget.user.name,
                      ),
                    ).then((reported) {
                      if (reported == true && mounted) {
                        Navigator.pop(context);
                      }
                    });
                  } else if (value == 'block') {
                    showDialog(
                      context: context,
                      builder: (context) => BlockUserDialog(
                        blockedUserId: widget.user.id,
                        blockedUserName: widget.user.name,
                      ),
                    ).then((blocked) {
                      if (blocked == true && mounted) {
                        Navigator.pop(context);
                      }
                    });
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: widget.user.photoUrls.isNotEmpty
                  ? Stack(
                      children: [
                        // Photo actuelle
                        PageView.builder(
                          itemCount: widget.user.photoUrls.length,
                          onPageChanged: (index) {
                            setState(() => _selectedPhotoIndex = index);
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              widget.user.photoUrlsFull[index],
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                        // Indicateurs de page
                        if (widget.user.photoUrls.length > 1)
                          Positioned(
                            top: 50,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                widget.user.photoUrls.length,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _selectedPhotoIndex == index
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
          ),

          // Informations de base
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom et âge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${widget.user.name}, ${widget.user.age}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.user.verified)
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 28,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Localisation
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'À proximité',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bio
                  if (widget.user.bio.isNotEmpty) ...[
                    const Text(
                      'À propos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.user.bio,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Informations détaillées
                  const Text(
                    'Informations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Informations de base
                  _buildInfoTile(Icons.cake, 'Âge', '${widget.user.age} ans'),
                  _buildInfoTile(Icons.wc, 'Genre', widget.user.gender),
                  if (widget.user.sexualOrientation != null && widget.user.sexualOrientation!.isNotEmpty)
                    _buildInfoTile(Icons.favorite, 'Orientation', widget.user.sexualOrientation!),
                  if (widget.user.height != null)
                    _buildInfoTile(Icons.height, 'Taille', '${widget.user.height} cm'),
                  if (widget.user.weight != null)
                    _buildInfoTile(Icons.fitness_center, 'Poids', '${widget.user.weight} kg'),
                  if (widget.user.bodyType != null && widget.user.bodyType!.isNotEmpty)
                    _buildInfoTile(Icons.accessibility_new, 'Silhouette', widget.user.bodyType!),

                  // Localisation
                  if (widget.user.city != null && widget.user.city!.isNotEmpty)
                    _buildInfoTile(Icons.location_city, 'Ville', widget.user.city!),
                  if (widget.user.country != null && widget.user.country!.isNotEmpty)
                    _buildInfoTile(Icons.flag, 'Pays', widget.user.country!),
                  if (widget.user.continent != null && widget.user.continent!.isNotEmpty)
                    _buildInfoTile(Icons.public, 'Continent', widget.user.continent!),

                  // Vie professionnelle et éducation
                  if (widget.user.occupation != null && widget.user.occupation!.isNotEmpty)
                    _buildInfoTile(Icons.work, 'Profession', widget.user.occupation!),
                  if (widget.user.education != null && widget.user.education!.isNotEmpty)
                    _buildInfoTile(Icons.school, 'Éducation', widget.user.education!),

                  // Situation personnelle
                  if (widget.user.maritalStatus != null && widget.user.maritalStatus!.isNotEmpty)
                    _buildInfoTile(Icons.people, 'Situation', widget.user.maritalStatus!),
                  if (widget.user.religion != null && widget.user.religion!.isNotEmpty)
                    _buildInfoTile(Icons.church, 'Religion', widget.user.religion!),

                  // Type de compte
                  _buildInfoTile(
                    Icons.workspace_premium,
                    'Abonnement',
                    widget.user.subscriptionPlan.toUpperCase(),
                  ),

                  const SizedBox(height: 24),

                  // Sports et hobbies
                  if (widget.user.sports.isNotEmpty) ...[
                    const Text(
                      'Sports',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.user.sports.map((sport) {
                        return Chip(
                          label: Text(sport),
                          backgroundColor: Colors.green[50],
                          labelStyle: const TextStyle(color: Colors.green),
                          avatar: const Icon(Icons.sports, size: 18, color: Colors.green),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (widget.user.hobbies.isNotEmpty) ...[
                    const Text(
                      'Loisirs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.user.hobbies.map((hobby) {
                        return Chip(
                          label: Text(hobby),
                          backgroundColor: Colors.orange[50],
                          labelStyle: const TextStyle(color: Colors.orange),
                          avatar: const Icon(Icons.interests, size: 18, color: Colors.orange),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Intérêts
                  if (widget.user.interests.isNotEmpty) ...[
                    const Text(
                      'Intérêts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.user.interests.map((interest) {
                        return Chip(
                          label: Text(interest),
                          backgroundColor: Colors.pink[50],
                          labelStyle: const TextStyle(color: Colors.pink),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Recherche
                  if (widget.user.lookingFor.isNotEmpty) ...[
                    const Text(
                      'Recherche',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.user.lookingFor.map((item) {
                        return Chip(
                          label: Text(item),
                          backgroundColor: Colors.purple[50],
                          labelStyle: const TextStyle(color: Colors.purple),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Vidéos
                  const Text(
                    'Vidéos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Grid de vidéos
          _isLoadingVideos
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              : _userVideos.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.video_library_outlined,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune vidéo',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.7,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final video = _userVideos[index];
                            return InkWell(
                              onTap: () => _playVideo(video),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Placeholder ou thumbnail
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.play_circle_outline,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    // Overlay avec infos
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.7),
                                            ],
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (video.title.isNotEmpty)
                                              Text(
                                                video.title,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.favorite,
                                                  color: Colors.pink,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${video.likes}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Icon(
                                                  Icons.visibility,
                                                  color: Colors.white70,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${video.views}',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _userVideos.length,
                        ),
                      ),
                    ),

          // Espacement en bas pour les boutons
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),

      // Boutons d'action (seulement si ce n'est pas son propre profil)
      bottomNavigationBar: !isOwnProfile
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Passer'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _likeUser,
                        icon: const Icon(Icons.favorite),
                        label: const Text('J\'aime'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.pink),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// Page de lecture de vidéo
class _VideoPlayerPage extends StatefulWidget {
  final VideoModel video;
  final BackendService backendService;

  const _VideoPlayerPage({
    required this.video,
    required this.backendService,
  });

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final urlParam = widget.video.videoUrl ?? widget.video.fileId;
    final videoUrl = widget.backendService.getVideoUrl(urlParam);
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    await _controller.initialize();
    _controller.setLooping(true);
    _controller.play();
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.video.title),
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}
