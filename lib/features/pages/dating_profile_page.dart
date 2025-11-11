import 'package:dating_app/core/services/appwrite_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../core/models/dating_user.dart';
import '../../core/models/video_model.dart';
import '../../core/services/backend_service.dart';
import '../../core/providers/auth_provider.dart';
import 'complete_profile_page.dart';
import 'edit_profile_page.dart';
import '../admin/admin_dashboard_page.dart';
import 'premium_page.dart';
import 'upload_profile_photo_page.dart';
import 'manage_videos_page.dart';
import '../../core/widgets/subscription_badge.dart';
import '../widgets/clay_video_button.dart';

class DatingProfilePage extends ConsumerStatefulWidget {
  const DatingProfilePage({super.key});

  @override
  ConsumerState<DatingProfilePage> createState() => _DatingProfilePageState();
}

class _DatingProfilePageState extends ConsumerState<DatingProfilePage> {
  final BackendService _backend = BackendService();

  DatingUser? _currentUser;
  List<VideoModel> _userVideos = [];
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isLoadingVideos = false;
  bool _isAdmin = false; // Flag pour savoir si l'utilisateur est admin

  // Compteurs
  int _likesCount = 0;
  int _matchesCount = 0;

  // Contrôleur vidéo actif global
  static VideoPlayerController? _activeVideoController;

  // Contrôleurs pour les carousels
  final PageController _photoCarouselController = PageController();
  int _currentPhotoPage = 0;
  final PageController _videoCarouselController = PageController();
  int _currentVideoPage = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  static final List<_VideoThumbnailState> _allVideoStates = [];

  static void registerVideoState(_VideoThumbnailState state) {
    _allVideoStates.add(state);
  }

  static void unregisterVideoState(_VideoThumbnailState state) {
    _allVideoStates.remove(state);
  }

  static void pauseAllVideos() {
    _activeVideoController?.pause();
    _activeVideoController = null;
    // Forcer tous les widgets à se mettre à jour
    for (var state in _allVideoStates) {
      if (state.mounted) {
        state._forceUpdatePlayingState();
      }
    }
  }

  static void setActiveController(VideoPlayerController controller) {
    if (_activeVideoController != null && _activeVideoController != controller) {
      print('⏸️ Pause vidéo précédente');
      _activeVideoController!.pause();
    }
    _activeVideoController = controller;
    print('▶️ Active vidéo actuelle');

    // Forcer tous les widgets à se mettre à jour
    for (var state in _allVideoStates) {
      if (state.mounted) {
        state._forceUpdatePlayingState();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les compteurs à chaque fois que la page devient visible
    if (_currentUser != null) {
      _loadCounters();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _photoCarouselController.dispose();
    _videoCarouselController.dispose();
    super.dispose();
  }

  Future<void> _checkIfAdmin() async {
    try {
      if (_currentUser == null) {
        print('⚠️ _currentUser est null, impossible de vérifier admin');
        return;
      }

      // Récupérer le profil utilisateur depuis la collection users
      final profileDoc = await _backend.getUserProfile(_currentUser!.id);
      final profileData = profileDoc is Map ? profileDoc : (profileDoc?.data ?? {});

      // Vérifier l'attribut isAdmin
      final isAdmin = profileData['isAdmin'] == true;

      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          
        });
      }

      print('🔐 Utilisateur isAdmin: $isAdmin');
    } catch (e) {
      print('⚠️ Erreur vérification admin: $e');
    }
  }

  Future<void> _loadProfile() async {
    try {
      print('📱 Chargement du profil...');
      // Utiliser getCurrentUser() pour obtenir les données fraîches directement
      final currentUserDoc = await _backend.getCurrentUser();
      final profileData = currentUserDoc is Map ? currentUserDoc : currentUserDoc.data;
      print('📄 Profile data: $profileData');

      final user = DatingUser.fromJson(profileData);
      print('✅ User chargé: ${user.name}');
      print('📸 Photos: ${user.photoUrls}');

      if (!mounted) return;
      _nameController.text = user.name;
      _ageController.text = user.age.toString();
      _bioController.text = user.bio;

      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });

      // Vérifier si l'utilisateur est admin
      _checkIfAdmin();

      // Charger les compteurs (likes et matches)
      _loadCounters();

      // Charger les vidéos de l'utilisateur
      _loadUserVideos(user.id);
    } catch (e, stackTrace) {
      print('❌ Erreur chargement profil: $e');

      // Si le profil n'existe pas (document_not_found), proposer de le créer
      if (e.toString().contains('document_not_found')) {
        print('⚠️ Profil non trouvé, proposition de création...');
        if (!mounted) return;
        setState(() => _isLoading = false);
        if (mounted) {
          _showCreateProfileDialog();
        }
      } else {
        print('Stack trace: $stackTrace');
        if (!mounted) return;
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur de chargement du profil: $e'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Réessayer',
                onPressed: () {
                  if (!mounted) return;
                  setState(() => _isLoading = true);
                  _loadProfile();
                },
              ),
            ),
          );
        }
      }
    }
  }

  // Méthode publique pour rafraîchir les compteurs (appelée depuis dating_home_page)
  Future<void> refreshCounters() async {
    await _loadCounters();
  }

  Future<void> _loadCounters() async {
    try {
      print('📊 Chargement des compteurs...');

      // Charger le nombre de matches
      final matchesCount = await _backend.getMatchesCount();

      // Charger le nombre de likes reçus
      final likesReceived = await _backend.getLikesReceived();
      final likesCount = (likesReceived.documents as List).length;

      print('✅ Matches: $matchesCount, Likes: $likesCount');

      if (!mounted) return;
      setState(() {
        _matchesCount = matchesCount;
        _likesCount = likesCount;
      });
    } catch (e) {
      print('❌ Erreur chargement compteurs: $e');
      // Ne pas bloquer l'interface si le chargement des compteurs échoue
    }
  }

  Future<void> _loadUserVideos(String userId) async {
    if (!mounted) return;
    setState(() => _isLoadingVideos = true);
    try {
      print('📹 Chargement des vidéos pour userId: $userId');
      final response = await _backend.getUserVideos(userId);
      print('📹 Réponse: ${response.documents.length} vidéos trouvées');

      final videos = (response.documents as List)
          .map((doc) {
            final data = doc is Map ? doc : doc.data;
            print('📹 Vidéo: $data');
            return VideoModel.fromJson(data);
          })
          .toList();

      for (var video in videos) {
        // Utiliser videoUrl si disponible (backend local), sinon fileId (Appwrite)
        final urlParam = video.videoUrl ?? video.fileId;
        final videoUrl = _backend.getVideoUrl(urlParam);
        print('📹 Video ID: ${video.id}, FileID: ${video.fileId}, VideoUrl: ${video.videoUrl}');
        print('📹 URL générée: $videoUrl');
      }

      if (!mounted) return;
      setState(() {
        _userVideos = videos;
        _isLoadingVideos = false;
      });
    } catch (e) {
      print('❌ Erreur chargement vidéos: $e');
      if (!mounted) return;
      setState(() => _isLoadingVideos = false);
    }
  }

  Future<void> _showCreateProfileDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Profil incomplet'),
        content: const Text(
          'Votre compte existe mais votre profil n\'a pas été créé correctement. '
          'Voulez-vous créer votre profil maintenant ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Créer mon profil'),
          ),
        ],
      ),
    );

    if (result == true) {
      _navigateToCompleteProfile();
    }
  }

  Future<void> _navigateToCompleteProfile() async {
    // Naviguer vers la page de complétion de profil
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompleteProfilePage(),
      ),
    );

    if (result == true) {
      // Recharger le profil après création
      if (!mounted) return;
      setState(() => _isLoading = true);
      _loadProfile();
    }
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;

    try {
      await _backend.updateUserProfile(
        userId: _currentUser!.id,
        data: {
          'name': _nameController.text,
          'age': int.tryParse(_ageController.text) ?? _currentUser!.age,
          'bio': _bioController.text,
        },
      );

      if (!mounted) return;
      setState(() => _isEditing = false);
      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      // D'abord, forcer la pause et le dispose de TOUTES les vidéos
      print('🛑 Logout: Dispose de toutes les vidéos');
      for (var state in _allVideoStates) {
        if (state.mounted && state._controller != null) {
          state._controller!.pause();
          state._controller!.dispose();
        }
      }
      _allVideoStates.clear();
      _activeVideoController = null;

      print('✅ Déconnexion en cours...');

      // Utiliser le authProvider pour déconnexion avec persistence
      await ref.read(authProvider.notifier).logout();

      print('✅ Déconnexion réussie - AuthWrapper va rediriger vers LoginPage');

      // Ne pas afficher de SnackBar car le widget va être détruit immédiatement
      // et remplacé par FlutterLoginPage via AuthWrapper
    } catch (e) {
      print('❌ Erreur de déconnexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur de déconnexion: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Si pas de profil après le chargement, afficher un message
    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_off,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Profil introuvable',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Votre profil n\'a pas pu être chargé.\nVoulez-vous le créer maintenant ?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _navigateToCompleteProfile,
                  icon: const Icon(Icons.add),
                  label: const Text('Créer mon profil'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _loadProfile();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer de charger'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with photo gallery
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_a_photo),
                tooltip: 'Gérer mes photos',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UploadProfilePhotoPage(currentUser: _currentUser!),
                    ),
                  );
                  if (result == true) {
                    _loadProfile();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.video_library),
                tooltip: 'Gérer mes vidéos',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageVideosPage(currentUser: _currentUser!),
                    ),
                  );
                  if (result == true) {
                    _loadProfile();
                    _loadUserVideos(_currentUser!.id);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Modifier le profil',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(currentUser: _currentUser!),
                    ),
                  );
                  if (result == true) {
                    _loadProfile();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'Migration',
                onPressed: () {
                  Navigator.pushNamed(context, '/migration');
                },
              ),
              IconButton(
                icon: const Icon(Icons.workspace_premium),
                tooltip: 'Upgrade Premium',
                onPressed: () {
                  Navigator.pushNamed(context, '/upgrade');
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Déconnexion',
                onPressed: () async {
                  // Afficher une confirmation avant de se déconnecter
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Déconnexion'),
                      content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Déconnexion'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    _logout();
                  }
                },
              ),
            ],
          ),

          // Profile content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar circulaire
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 0, bottom: 16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.pink, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _currentUser!.photoUrlsFull.isNotEmpty
                            ? NetworkImage(_currentUser!.photoUrlsFull.first)
                            : null,
                        backgroundColor: Colors.grey[300],
                        child: _currentUser!.photoUrlsFull.isEmpty
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                    ),
                  ),

                  // Name and age
                  if (_isEditing) ...[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Âge',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_currentUser!.name}, ${_currentUser!.age}',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        SubscriptionBadge(plan: _currentUser!.effectivePlan),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 20, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentUser!.latitude.toStringAsFixed(2)}, ${_currentUser!.longitude.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats cards
                  Row(
                    children: [
                      Expanded(child: _StatCard(title: 'Likes', value: '$_likesCount', icon: Icons.favorite)),
                      const SizedBox(width: 16),
                      Expanded(child: _StatCard(title: 'Matchs', value: '$_matchesCount', icon: Icons.people)),
                      const SizedBox(width: 16),
                      Expanded(child: _StatCard(title: 'Vidéos', value: '${_currentUser!.videoIds.length}', icon: Icons.video_library)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Premium button (if not premium)
                  if (_currentUser!.effectivePlan == 'free')
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.amber, Colors.orange, Colors.deepOrange],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PremiumPage(currentUser: _currentUser!),
                              ),
                            );
                          },
                          icon: const Icon(Icons.star),
                          label: const Text('Passer Premium'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  if (_currentUser!.effectivePlan == 'free')
                    const SizedBox(height: 16),

                  // Admin button - visible uniquement pour les utilisateurs avec le label "admin"
                  if (_isAdmin) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminDashboardPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Accès Admin'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.deepPurple,
                          side: const BorderSide(color: Colors.deepPurple),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // My photos section - Carousel de thumbnails
                  if (_currentUser!.photoUrlsFull.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mes photos',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_currentUser!.photoUrlsFull.length} photo(s)',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: PageView.builder(
                        controller: _photoCarouselController,
                        onPageChanged: (index) {
                          setState(() => _currentPhotoPage = index);
                        },
                        itemCount: (_currentUser!.photoUrlsFull.length / 3).ceil(),
                        itemBuilder: (context, pageIndex) {
                          final startIndex = pageIndex * 3;
                          final endIndex = (startIndex + 3).clamp(0, _currentUser!.photoUrlsFull.length);

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = startIndex; i < endIndex; i++)
                                Container(
                                  width: 100,
                                  height: 120,
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: NetworkImage(_currentUser!.photoUrlsFull[i]),
                                      fit: BoxFit.cover,
                                    ),
                                    border: i == 0
                                        ? Border.all(color: Colors.pink, width: 3)
                                        : null,
                                  ),
                                  child: i == 0
                                      ? Align(
                                          alignment: Alignment.topLeft,
                                          child: Container(
                                            margin: const EdgeInsets.all(4),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.pink,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Principale',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Indicateurs de page
                    if ((_currentUser!.photoUrlsFull.length / 3).ceil() > 1) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          (_currentUser!.photoUrlsFull.length / 3).ceil(),
                          (index) => Container(
                            width: _currentPhotoPage == index ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: _currentPhotoPage == index ? Colors.pink : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],

                  // Bouton pour ajouter une vidéo
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageVideosPage(currentUser: _currentUser!),
                          ),
                        );
                        if (result == true) {
                          _loadProfile();
                          _loadUserVideos(_currentUser!.id);
                        }
                      },
                      icon: const Icon(Icons.videocam),
                      label: const Text('Gérer mes vidéos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // My videos section - Carousel
                  if (_userVideos.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mes vidéos',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_userVideos.length} vidéo(s)',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _isLoadingVideos
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            height: 200,
                            child: PageView.builder(
                              controller: _videoCarouselController,
                              onPageChanged: (index) {
                                setState(() => _currentVideoPage = index);
                                // Pauser toutes les vidéos au changement de page
                                pauseAllVideos();
                              },
                              itemCount: (_userVideos.length / 2).ceil(), // 2 vidéos par page
                              itemBuilder: (context, pageIndex) {
                                final startIndex = pageIndex * 2;
                                final endIndex = (startIndex + 2).clamp(0, _userVideos.length);

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var i = startIndex; i < endIndex; i++)
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          child: _VideoThumbnail(
                                            video: _userVideos[i],
                                            backendService: _backend,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),

                    // Indicateurs de page pour vidéos
                    if (!_isLoadingVideos && (_userVideos.length / 2).ceil() > 1) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          (_userVideos.length / 2).ceil(),
                          (index) => Container(
                            width: _currentVideoPage == index ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: _currentVideoPage == index ? Colors.pink : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],

                  // Bio
                  const Text(
                    'Bio',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_isEditing)
                    TextField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        hintText: 'Parlez-nous de vous...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    )
                  else
                    Text(
                      _currentUser!.bio.isNotEmpty
                          ? _currentUser!.bio
                          : 'Aucune bio pour le moment',
                      style: TextStyle(
                        fontSize: 16,
                        color: _currentUser!.bio.isEmpty ? Colors.grey : Colors.black,
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Interests
                  const Text(
                    'Intérêts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_currentUser!.interests.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currentUser!.interests.map((interest) {
                        return Chip(
                          label: Text(interest),
                          backgroundColor: Colors.pink[50],
                          deleteIcon: _isEditing ? const Icon(Icons.close, size: 18) : null,
                          onDeleted: _isEditing ? () {} : null,
                        );
                      }).toList(),
                    )
                  else
                    Text(
                      'Aucun intérêt ajouté',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.pink, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour afficher un thumbnail vidéo avec lecture intégrée
class _VideoThumbnail extends StatefulWidget {
  final VideoModel video;
  final BackendService backendService;

  const _VideoThumbnail({
    required this.video,
    required this.backendService,
  });

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _DatingProfilePageState.registerVideoState(this);
    // Initialiser automatiquement pour afficher le thumbnail
    _initializeVideo();
  }

  void _forceUpdatePlayingState() {
    if (_controller != null && mounted) {
      final shouldBePlaying = _controller!.value.isPlaying;
      if (_isPlaying != shouldBePlaying) {
        setState(() => _isPlaying = shouldBePlaying);
      }
    }
  }

  Future<void> _initializeVideo() async {
    final urlParam = widget.video.videoUrl ?? widget.video.fileId;
    final videoUrl = widget.backendService.getVideoUrl(urlParam);
    print('📹 Initialisation thumbnail vidéo: $videoUrl');
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try {
      await _controller!.initialize();

      // Ajouter un listener pour synchroniser l'état
      _controller!.addListener(() {
        if (mounted) {
          final isPlaying = _controller!.value.isPlaying;
          if (_isPlaying != isPlaying) {
            setState(() => _isPlaying = isPlaying);
          }
        }
      });

      if (mounted) {
        setState(() => _isInitialized = true);
      }
      // IMPORTANT: Volume à 0 par défaut pour éviter les sons qui se superposent
      _controller!.setVolume(0.0);
      // Pause à la première frame pour le thumbnail
      _controller!.seekTo(Duration.zero);
      _controller!.pause();

      print('✅ Vidéo initialisée avec volume = 0');
    } catch (e) {
      print('❌ Erreur initialisation vidéo: $e');
    }
  }

  @override
  void dispose() {
    _DatingProfilePageState.unregisterVideoState(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    print('🎯 Clic sur vidéo - isInitialized: $_isInitialized');

    if (_controller == null || !_isInitialized) {
      print('❌ Vidéo non initialisée');
      return;
    }

    if (_controller!.value.isPlaying) {
      // Si cette vidéo joue, l'arrêter
      print('⏸️ Arrêt de cette vidéo');
      _controller!.pause();
      _controller!.setVolume(0);
      setState(() => _isPlaying = false);
    } else {
      // ÉTAPE 1: Arrêter TOUTES les autres vidéos de force
      print('🛑 Arrêt de toutes les autres vidéos');
      int stoppedCount = 0;

      for (var state in _DatingProfilePageState._allVideoStates) {
        if (state._controller != null && state._controller != _controller) {
          state._controller!.pause();
          state._controller!.setVolume(0);
          if (state.mounted) {
            state.setState(() => state._isPlaying = false);
          }
          stoppedCount++;
        }
      }
      print('✅ Total arrêté: $stoppedCount vidéos');

      // ÉTAPE 2: Jouer UNIQUEMENT cette vidéo
      print('▶️ Lecture avec volume 1.0');
      _controller!.setVolume(1.0);
      _controller!.play();
      _controller!.setLooping(false);
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              if (_isInitialized && _controller != null)
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              if (!_isPlaying || !_isInitialized)
                Center(
                  child: Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.video.title.isNotEmpty)
                      Text(
                        widget.video.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 12, color: Colors.pink),
                        const SizedBox(width: 4),
                        Text('${widget.video.likes}', style: const TextStyle(color: Colors.white, fontSize: 10, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                        const SizedBox(width: 8),
                        const Icon(Icons.visibility, size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text('${widget.video.views}', style: const TextStyle(color: Colors.white, fontSize: 10, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
