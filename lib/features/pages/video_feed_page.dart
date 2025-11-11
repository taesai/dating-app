import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../core/models/dating_user.dart';
import '../../core/models/video_model.dart';
import '../../core/services/backend_service.dart';
import '../../core/providers/likes_provider.dart';
import 'user_detail_profile_page.dart';
import 'search_preferences_page.dart';

class VideoFeedPage extends StatefulWidget {
  const VideoFeedPage({super.key});

  @override
  State<VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<VideoFeedPage> {
  final BackendService _backend = BackendService();
  final PageController _pageController = PageController();
  final Map<int, GlobalKey<_VideoItemState>> _videoKeys = {};

  List<VideoModel> _videos = [];
  Map<String, DatingUser> _videoUsers = {};
  bool _isLoading = true;
  int _currentPage = 0;
  String? _currentUserId;
  DatingUser? _currentUserProfile; // Profil complet pour filtres

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndVideos();
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      // Pauser la vidéo précédente
      _videoKeys[_currentPage]?.currentState?.pauseVideo();
      // Jouer la nouvelle vidéo
      _videoKeys[page]?.currentState?.playVideo();
      setState(() => _currentPage = page);
      print('📄 Changement de page: $_currentPage -> $page');
    }
  }

  Future<void> _loadCurrentUserAndVideos() async {
    try {
      // Charger l'utilisateur actuel d'abord
      final currentUser = await _backend.getCurrentUser();
      _currentUserId = currentUser.$id;

      // Charger les vidéos
      await _loadVideos();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _loadVideos() async {
    print('🚨🚨🚨 CHARGEMENT VIDÉOS - CODE À JOUR 🚨🚨🚨');
    try {
      final response = await _backend.getVideos(limit: 50);
      final videos = (response.documents as List)
          .map((doc) {
            final videoData = doc is Map ? doc : doc.data;
            return VideoModel.fromJson(videoData);
          })
          .where((video) => video.userId != _currentUserId && video.isApproved) // Filtrer les vidéos de l'utilisateur actuel
          .toList();

      // Load user info for each video and filter by profile approval
      print('🎬 Début chargement de ${videos.length} vidéos');
      final approvedVideos = <VideoModel>[];
      for (var video in videos) {
        try {
          final userDoc = await _backend.getUserProfile(video.userId);
          final userData = userDoc is Map ? userDoc : userDoc.data;
          final user = DatingUser.fromJson(userData);

          print('🔍 User ${user.name} - isProfileApproved: ${user.isProfileApproved}');

          // Ne garder que les vidéos d'utilisateurs explicitement approuvés (true)
          if (user.isProfileApproved == true) {
            _videoUsers[video.userId] = user;
            approvedVideos.add(video);
            print('✅ Vidéo de ${user.name} ajoutée au feed');
          } else {
            print('❌ Vidéo de ${user.name} rejetée (profil non approuvé)');
          }
        } catch (e) {
          print('⚠️ Erreur chargement user: $e');
        }
      }

      print('📊 Total vidéos approuvées: ${approvedVideos.length}/${videos.length}');

      // Appliquer les filtres de recherche de l'utilisateur sur les vidéos approuvées
      final filteredVideos = _applySearchFilters(approvedVideos);

      setState(() {
        _videos = filteredVideos;
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
  void dispose() {
    // Pauser et disposer toutes les vidéos
    for (var key in _videoKeys.values) {
      key.currentState?.pauseVideo();
      key.currentState?.disposeVideo();
    }
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _videoKeys.clear();
    super.dispose();
  }

  /// Filtrer les vidéos selon les préférences de recherche de l'utilisateur
  List<VideoModel> _applySearchFilters(List<VideoModel> videos) {
    if (_currentUserProfile == null) return videos;

    return videos.where((video) {
      final videoOwner = _videoUsers[video.userId];
      if (videoOwner == null) return false;

      // Filtre 1: Genre recherché
      if (_currentUserProfile!.preferredGenders != null &&
          _currentUserProfile!.preferredGenders!.isNotEmpty &&
          !_currentUserProfile!.preferredGenders!.contains('tous')) {
        if (!_currentUserProfile!.preferredGenders!.contains(videoOwner.gender.toLowerCase())) {
          return false;
        }
      }

      // Filtre 2: Âge recherché
      if (_currentUserProfile!.preferredAgeRange != null) {
        final minAge = _currentUserProfile!.preferredAgeRange!.start.toInt();
        final maxAge = _currentUserProfile!.preferredAgeRange!.end.toInt();
        if (videoOwner.age < minAge || videoOwner.age > maxAge) {
          return false;
        }
      }

      // Filtre 3: Continent recherché
      if (_currentUserProfile!.preferredContinents != null &&
          _currentUserProfile!.preferredContinents!.isNotEmpty &&
          videoOwner.continent != null) {
        if (!_currentUserProfile!.preferredContinents!.contains(videoOwner.continent)) {
          return false;
        }
      }

      // Filtre 4: Pays recherché
      if (_currentUserProfile!.preferredCountries != null &&
          _currentUserProfile!.preferredCountries!.isNotEmpty &&
          videoOwner.country != null) {
        if (!_currentUserProfile!.preferredCountries!.contains(videoOwner.country)) {
          return false;
        }
      }

      return true; // Toutes les conditions passées
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_videos.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, size: 100, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Aucune vidéo disponible', style: TextStyle(fontSize: 20, color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPreferencesPage()),
              ).then((_) {
                // Recharger les vidéos après modification des préférences
                _loadCurrentUserAndVideos();
              });
            },
            tooltip: 'Critères de recherche',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          // Créer une clé unique pour chaque vidéo
          if (!_videoKeys.containsKey(index)) {
            _videoKeys[index] = GlobalKey<_VideoItemState>();
          }

          return _VideoItem(
            key: _videoKeys[index],
            video: _videos[index],
            user: _videoUsers[_videos[index].userId],
            backendService: _backend,
            currentUserId: _currentUserId ?? '',
            isCurrentPage: index == _currentPage,
          );
        },
      ),
    );
  }
}

class _VideoItem extends ConsumerStatefulWidget {
  final VideoModel video;
  final DatingUser? user;
  final BackendService backendService;
  final String currentUserId;
  final bool isCurrentPage;

  const _VideoItem({
    super.key,
    required this.video,
    required this.user,
    required this.backendService,
    required this.currentUserId,
    required this.isCurrentPage,
  });

  @override
  ConsumerState<_VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends ConsumerState<_VideoItem> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  double _swipeOffset = 0.0;
  double _verticalSwipeOffset = 0.0;
  late AnimationController _animationController;
  bool _isInitialized = false;
  bool _isVisible = false;

  @override
  bool get wantKeepAlive => true; // Garde l'état du widget

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialiser le compteur de likes de cette vidéo ET charger les likes de l'utilisateur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(likesProvider.notifier).initializeLikeCount(widget.video.id, widget.video.likes);

      // Charger les likes de l'utilisateur si pas encore fait
      ref.read(likesProvider.notifier).loadUserLikes(widget.currentUserId);

      // Initialiser seulement si visible
      _checkVisibilityAndInitialize();
    });
  }

  @override
  void didUpdateWidget(_VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la page devient visible, initialiser la vidéo
    if (widget.isCurrentPage && !oldWidget.isCurrentPage) {
      _checkVisibilityAndInitialize();
    }
    // Si la page devient invisible, pauser la vidéo
    else if (!widget.isCurrentPage && oldWidget.isCurrentPage) {
      pauseVideo();
    }
  }

  void _checkVisibilityAndInitialize() {
    if (!_isInitialized && mounted && widget.isCurrentPage) {
      _isVisible = true;
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    if (_isInitialized) return;

    print('🎬 Initialisation vidéo: ${widget.video.title} (${widget.video.id})');

    final urlParam = widget.video.videoUrl ?? widget.video.fileId;
    final videoUrl = widget.backendService.getVideoUrl(urlParam);
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    try {
      await _videoController!.initialize();

      // IMPORTANT: Volume à 0 par défaut pour éviter la cacophonie
      _videoController!.setVolume(0.0);

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false, // NE PAS jouer automatiquement
        looping: true,
        showControls: false,
        aspectRatio: _videoController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.pink,
          handleColor: Colors.pink,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
      );

      _isInitialized = true;
      if (mounted) setState(() {});
      print('✅ Vidéo initialisée (muette): ${widget.video.title}');
    } catch (e) {
      print('❌ Erreur initialisation vidéo ${widget.video.title}: $e');
    }
  }

  @override
  void dispose() {
    print('🗑️ Dispose vidéo: ${widget.video.title}');
    _videoController?.pause();
    _videoController?.dispose();
    _chewieController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void pauseVideo() {
    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.setVolume(0.0); // Mute quand en pause
    }
  }

  void playVideo() {
    if (_videoController != null && _isInitialized) {
      // Jouer la vidéo MAIS SANS SON (volume reste à 0)
      // L'utilisateur doit TAP pour activer le son
      print('▶️ Lecture vidéo MUETTE pour: ${widget.video.title}');
      _videoController!.play();
    }
  }

  void playVideoWithSound() {
    if (_videoController != null && _isInitialized) {
      print('🔊 Activation du son pour: ${widget.video.title}');
      _videoController!.setVolume(1.0);
      _videoController!.play();
    }
  }

  void disposeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _chewieController?.dispose();
  }

  void _toggleLike() {
    final currentCount = ref.read(likesProvider.notifier).getLikeCount(widget.video.id, widget.video.likes);
    ref.read(likesProvider.notifier).toggleLike(widget.video.id, widget.currentUserId, currentCount);
  }

  void _handleSwipeRight() {
    // Toggle like via Riverpod
    final currentCount = ref.read(likesProvider.notifier).getLikeCount(widget.video.id, widget.video.likes);
    ref.read(likesProvider.notifier).toggleLike(widget.video.id, widget.currentUserId, currentCount);

    // Afficher un feedback visuel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: Colors.white),
            const SizedBox(width: 8),
            Text('${widget.user?.name ?? "Utilisateur"} a été liké !'),
          ],
        ),
        backgroundColor: Colors.pink,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  void _handleSwipeLeft() {
    // Naviguer vers le profil de l'utilisateur
    if (widget.user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _UserProfileDetailPage(user: widget.user!),
        ),
      );
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _swipeOffset += details.delta.dx;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    const swipeThreshold = 100.0;

    if (_swipeOffset > swipeThreshold) {
      // Swipe droite : Like
      _handleSwipeRight();
    } else if (_swipeOffset < -swipeThreshold) {
      // Swipe gauche : Profil
      _handleSwipeLeft();
    }

    // Reset l'offset
    setState(() {
      _swipeOffset = 0.0;
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _verticalSwipeOffset += details.delta.dy;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    const swipeThreshold = 80.0; // Seuil plus bas pour faciliter le swipe

    if (_verticalSwipeOffset > swipeThreshold) {
      // Swipe vers le bas : Ouvrir le profil
      print('📱 Swipe vers le bas détecté! Navigation vers le profil...');
      _navigateToUserProfile();
    }

    // Reset l'offset
    setState(() {
      _verticalSwipeOffset = 0.0;
    });
  }

  void _navigateToUserProfile() {
    if (widget.user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserDetailProfilePage(
            user: widget.user!,
            currentUserId: widget.currentUserId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Pour AutomaticKeepAliveClientMixin

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Player en plein écran
        _chewieController != null && _videoController != null
            ? GestureDetector(
                onTap: () {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                },
                onDoubleTap: () {
                  print('🔥 Double-tap détecté! Navigation vers le profil...');
                  _navigateToUserProfile();
                },
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                child: Stack(
                  children: [
                    Transform.translate(
                      offset: Offset(_swipeOffset * 0.3, 0), // Effet visuel du swipe
                      child: SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _videoController!.value.size.width,
                            height: _videoController!.value.size.height,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                      ),
                    ),
                    // Indicateur de buffering
                    if (_videoController!.value.isBuffering)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Chargement de la vidéo...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : Container(color: Colors.black, child: const Center(child: CircularProgressIndicator())),

        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              stops: const [0.6, 1.0],
            ),
          ),
        ),

        // User info and buttons
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.user != null) ...[
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: widget.user!.photoUrlsFull.isNotEmpty
                                  ? NetworkImage(widget.user!.photoUrlsFull.first)
                                  : null,
                              child: widget.user!.photoUrlsFull.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${widget.user!.name}, ${widget.user!.age}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (widget.video.description.isNotEmpty) ...[
                        Text(
                          widget.video.description,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Action buttons
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final likesState = ref.watch(likesProvider);
                        final isLiked = likesState.userLikes[widget.video.id] ?? false;
                        final likeCount = likesState.likeCounts[widget.video.id] ?? widget.video.likes;
                        return _ActionButton(
                          icon: isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.white,
                          label: likeCount.toString(),
                          onPressed: _toggleLike,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _ActionButton(
                      icon: Icons.comment,
                      color: Colors.white,
                      label: '0',
                      onPressed: () {},
                    ),
                    const SizedBox(height: 16),
                    _ActionButton(
                      icon: Icons.share,
                      color: Colors.white,
                      label: 'Partager',
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Indicateurs visuels de swipe horizontal
        if (_swipeOffset.abs() > 20) ...[
          // Swipe droite : Like
          if (_swipeOffset > 0)
            Positioned(
              left: 40,
              top: MediaQuery.of(context).size.height / 2 - 60,
              child: Opacity(
                opacity: (_swipeOffset / 100).clamp(0.0, 1.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),

          // Swipe gauche : Profil
          if (_swipeOffset < 0)
            Positioned(
              right: 40,
              top: MediaQuery.of(context).size.height / 2 - 60,
              child: Opacity(
                opacity: (_swipeOffset.abs() / 100).clamp(0.0, 1.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: color, size: 32),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}

// Page de profil détaillé affichée lors du swipe gauche
class _UserProfileDetailPage extends StatelessWidget {
  final DatingUser user;

  const _UserProfileDetailPage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Photo principale en header
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: user.photoUrlsFull.isNotEmpty
                  ? Image.network(
                      user.photoUrlsFull.first,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.person, size: 100, color: Colors.white),
                    ),
            ),
          ),

          // Informations du profil
          SliverToBoxAdapter(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom et âge
                  Row(
                    children: [
                      Text(
                        '${user.name}, ${user.age}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user.verified) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.verified, color: Colors.blue, size: 28),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Localisation
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        'Lat: ${user.latitude.toStringAsFixed(2)}, Long: ${user.longitude.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bio
                  if (user.bio.isNotEmpty) ...[
                    const Text(
                      'À propos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.bio,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Détails
                  _InfoCard(
                    icon: Icons.work,
                    title: 'Profession',
                    value: user.occupation ?? 'Non renseigné',
                  ),
                  _InfoCard(
                    icon: Icons.school,
                    title: 'Éducation',
                    value: user.education ?? 'Non renseigné',
                  ),
                  _InfoCard(
                    icon: Icons.height,
                    title: 'Taille',
                    value: user.height ?? 'Non renseigné',
                  ),

                  // Centres d'intérêt
                  if (user.interests.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Centres d\'intérêt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.interests.map((interest) {
                        return Chip(
                          label: Text(interest),
                          backgroundColor: Colors.pink.withOpacity(0.2),
                          labelStyle: const TextStyle(color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ],

                  // Boutons d'action
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${user.name} a été liké !'),
                                backgroundColor: Colors.pink,
                              ),
                            );
                          },
                          icon: const Icon(Icons.favorite),
                          label: const Text('J\'aime'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Passer'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.white),
                          ),
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
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.pink, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
