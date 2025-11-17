import 'package:flutter/material.dart';
import '../../core/widgets/rive_loader.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../core/widgets/rive_loader.dart';
import 'package:latlong2/latlong.dart';
import '../../core/widgets/rive_loader.dart';
import '../../core/models/dating_user.dart';
import '../../core/widgets/rive_loader.dart';
import '../../core/models/video_model.dart';
import '../../core/widgets/rive_loader.dart';
import '../../core/services/backend_service.dart';
import '../../core/widgets/rive_loader.dart';
import '../../core/utils/page_transitions.dart';
import '../../core/widgets/rive_loader.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/widgets/rive_loader.dart';
import '../widgets/animated_like_card.dart';
import '../../core/widgets/rive_loader.dart';
import 'dating_home_page.dart';
import '../../core/widgets/rive_loader.dart';
import 'user_detail_profile_page.dart';
import '../../core/widgets/rive_loader.dart';

class LikesPage extends StatefulWidget {
  const LikesPage({super.key});

  @override
  State<LikesPage> createState() => _LikesPageState();
}

class VideoLike {
  final String id;
  final DatingUser user;
  final VideoModel video;
  final String createdAt;

  VideoLike({
    required this.id,
    required this.user,
    required this.video,
    required this.createdAt,
  });
}

class _LikesPageState extends State<LikesPage> with SingleTickerProviderStateMixin {
  final BackendService _backend = BackendService();
  late TabController _tabController;

  List<VideoLike> _videoLikesReceived = [];
  List<VideoLike> _videoLikesSent = [];
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLikes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLikes() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final currentUser = await _backend.getCurrentUser();
      _currentUserId = currentUser is Map ? currentUser['id'] : currentUser.$id;

      // Charger les likes reçus ET envoyés en parallèle
      await Future.wait([
        _loadLikesReceived(),
        _loadLikesSent(),
      ]);

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Erreur _loadLikes: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _loadLikesReceived() async {
    try {
      // Récupérer les likes vidéo reçus
      final response = await _backend.getLikesReceived();

      List<VideoLike> videoLikes = [];
      // Map pour dédoublonner par userId (un seul like par utilisateur)
      Map<String, VideoLike> uniqueLikes = {};

      // Gérer les deux types de retour possibles (DocumentList ou Map)
      final documents = response is Map ? (response['documents'] ?? []) : response.documents;

      print('📊 ${documents.length} likes reçus à charger');

      // Pré-filtrer pour éviter les doublons
      final uniqueUserIds = <String>{};
      final filteredDocs = documents.where((doc) {
        final likeData = doc is Map ? doc : doc.data;
        final userId = likeData['userId'];
        if (uniqueUserIds.contains(userId)) return false;
        uniqueUserIds.add(userId);
        return true;
      }).toList();

      print('👥 ${filteredDocs.length} utilisateurs uniques à charger');

      // Charger TOUS les profils et vidéos en PARALLÈLE
      final List<Future<VideoLike?>> futures = [];

      for (var doc in filteredDocs) {
        final future = () async {
          try {
            final likeData = doc is Map ? doc : doc.data;
            final userId = likeData['userId'];
            final videoId = likeData['videoId'];

            // Charger user et vidéo en parallèle
            final results = await Future.wait([
              _backend.getUserProfile(userId),
              _backend.getVideo(videoId),
            ]);

            final userDoc = results[0];
            final videoDoc = results[1];

            final userData = userDoc is Map ? userDoc : userDoc.data;
            final videoData = videoDoc is Map ? videoDoc : videoDoc.data;

            return VideoLike(
              id: likeData['\$id'] ?? likeData['id'] ?? '',
              user: DatingUser.fromJson(userData),
              video: VideoModel.fromJson(videoData),
              createdAt: likeData['createdAt'] ?? '',
            );
          } catch (e) {
            print('❌ Erreur chargement like reçu: $e');
            return null;
          }
        }();
        futures.add(future);
      }

      final results = await Future.wait(futures);

      // Filtrer les nulls
      for (var like in results) {
        if (like != null) {
          uniqueLikes[like.user.id] = like;
        }
      }

      print('✅ ${uniqueLikes.length} likes reçus chargés');

      // Convertir la map en liste
      videoLikes = uniqueLikes.values.toList();

      print('📋 Liste finale des likes reçus: ${videoLikes.length} éléments');
      for (var like in videoLikes) {
        print('   - ${like.user.name} (vidéo: ${like.video.id})');
      }

      if (!mounted) return;
      setState(() {
        _videoLikesReceived = videoLikes;
        print('✅ setState appelé: _videoLikesReceived contient ${_videoLikesReceived.length} likes');
      });
    } catch (e) {
      print('❌ Erreur _loadLikesReceived: $e');
    }
  }

  Future<void> _loadLikesSent() async {
    try {
      // Récupérer les likes vidéo envoyés
      final response = await _backend.getLikedVideos();

      List<VideoLike> videoLikes = [];
      // Map pour dédoublonner par userId (un seul like par utilisateur)
      Map<String, VideoLike> uniqueLikes = {};

      // Gérer les deux types de retour possibles (DocumentList ou Map)
      final documents = response is Map ? (response['documents'] ?? []) : response.documents;

      print('📊 ${documents.length} likes envoyés à charger');

      // Charger TOUTES les vidéos en PARALLÈLE d'abord
      final List<Future<Map<String, dynamic>?>> videoFutures = [];

      for (var doc in documents) {
        final future = () async {
          try {
            final likeData = doc is Map ? doc : doc.data;
            final videoId = likeData['videoId'];
            final videoDoc = await _backend.getVideo(videoId);
            final videoData = videoDoc is Map ? videoDoc : videoDoc.data;
            return {
              'likeData': likeData,
              'video': VideoModel.fromJson(videoData),
            };
          } catch (e) {
            print('❌ Erreur chargement vidéo: $e');
            return null;
          }
        }();
        videoFutures.add(future);
      }

      final videoResults = await Future.wait(videoFutures);

      // Filtrer pour garder un seul like par utilisateur
      final uniqueUserIds = <String>{};
      final filteredResults = videoResults.where((result) {
        if (result == null) return false;
        final userId = (result['video'] as VideoModel).userId;
        if (uniqueUserIds.contains(userId)) return false;
        uniqueUserIds.add(userId);
        return true;
      }).toList();

      print('👥 ${filteredResults.length} utilisateurs uniques à charger');

      // Charger TOUS les profils utilisateurs en PARALLÈLE
      final List<Future<VideoLike?>> userFutures = [];

      for (var result in filteredResults) {
        final future = () async {
          try {
            final video = result!['video'] as VideoModel;
            final likeData = result['likeData'];
            final userId = video.userId;

            final userDoc = await _backend.getUserProfile(userId);
            final userData = userDoc is Map ? userDoc : userDoc.data;

            return VideoLike(
              id: likeData['\$id'] ?? likeData['id'] ?? '',
              user: DatingUser.fromJson(userData),
              video: video,
              createdAt: likeData['createdAt'] ?? '',
            );
          } catch (e) {
            print('❌ Erreur chargement profil: $e');
            return null;
          }
        }();
        userFutures.add(future);
      }

      final userResults = await Future.wait(userFutures);

      // Filtrer les nulls
      for (var like in userResults) {
        if (like != null) {
          uniqueLikes[like.user.id] = like;
        }
      }

      print('✅ ${uniqueLikes.length} likes envoyés chargés');

      // Convertir la map en liste
      videoLikes = uniqueLikes.values.toList();

      print('📋 Liste finale des likes envoyés: ${videoLikes.length} éléments');
      for (var like in videoLikes) {
        print('   - ${like.user.name} (vidéo: ${like.video.id})');
      }

      if (!mounted) return;
      setState(() {
        _videoLikesSent = videoLikes;
        print('✅ setState appelé: _videoLikesSent contient ${_videoLikesSent.length} likes');
      });
    } catch (e) {
      print('❌ Erreur _loadLikesSent: $e');
    }
  }

  Future<void> _likeBack(DatingUser user) async {
    if (_currentUserId == null) return;

    try {
      print('💕 Like retour pour ${user.name}');

      final result = await _backend.likeUser(
        fromUserId: _currentUserId!,
        toUserId: user.id,
      );

      if (result != null && result['isMatch'] == true) {
        print('💕 C\'EST UN MATCH avec ${user.name}!');
        if (mounted) {
          _showMatchDialog(user);
          // Notifier le parent pour rafraîchir les compteurs
          _notifyParentToRefresh();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❤️ Vous avez liké ${user.name}'),
              backgroundColor: Colors.pink,
              duration: const Duration(seconds: 2),
            ),
          );
          // Notifier le parent pour rafraîchir les compteurs
          _notifyParentToRefresh();
        }
      }

      // Recharger la liste
      _loadLikes();
    } catch (e) {
      final errorMsg = e.toString();
      print('❌ Erreur _likeBack: $errorMsg');

      // Si c'est l'erreur "Déjà liké", c'est un match !
      if (errorMsg.contains('Déjà liké')) {
        print('💕 Déjà liké = MATCH avec ${user.name}!');
        if (mounted) {
          _showMatchDialog(user);
          _notifyParentToRefresh();
        }
        _loadLikes();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  void _notifyParentToRefresh() {
    // Trouver le DatingHomePage parent et déclencher le refresh
    if (mounted) {
      final homePageState = context.findAncestorStateOfType<DatingHomePageState>();
      homePageState?.refreshCounters();
    }
  }

  Future<void> _viewProfile(DatingUser user) async {
    // Ouvrir la page de profil avec animation scale
    final result = await context.pushWithScale(
      UserDetailProfilePage(
        user: user,
        currentUserId: _currentUserId,
      ),
    );

    // Si un like a été effectué depuis la page de profil, recharger la liste
    if (result == true) {
      _loadLikes();
      _notifyParentToRefresh();
    }
  }

  void _showMatchDialog(DatingUser user) {
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
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous et ${user.name} vous aimez mutuellement !',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.pink,
                ),
                child: const Text('Super !'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLikesReceivedView() {
    if (_videoLikesReceived.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun like reçu',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos vidéos n\'ont pas encore été likées',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = ResponsiveHelper.isTablet(context);
        final isDesktop = ResponsiveHelper.isDesktop(context);

        if (isTablet || isDesktop) {
          // Layout tablette/desktop : Liste à gauche, carte à droite
          return Row(
            children: [
              // Liste des likes
              Expanded(
                flex: 1,
                child: _buildLikesList(_videoLikesReceived),
              ),
              // Carte avec markers
              Expanded(
                flex: 2,
                child: _buildMap(_videoLikesReceived.map((like) => like.user).toList()),
              ),
            ],
          );
        }

        // Layout mobile : Grille simple
        return _buildLikesList(_videoLikesReceived);
      },
    );
  }

  Widget _buildLikesList(List<VideoLike> likes) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = ResponsiveHelper.isTablet(context);
        final isDesktop = ResponsiveHelper.isDesktop(context);

        // En mode tablette/desktop avec carte, afficher une liste verticale compacte
        if ((isTablet || isDesktop) && constraints.maxWidth < 400) {
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: likes.length,
            itemBuilder: (context, index) {
              final videoLike = likes[index];
              final user = videoLike.user;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.photoUrlsFull.isNotEmpty
                        ? NetworkImage(user.photoUrlsFull.first)
                        : null,
                    child: user.photoUrlsFull.isEmpty
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${user.age} ans',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => _viewProfile(user),
                ),
              );
            },
          );
        }

        // En mode mobile ou desktop plein écran, afficher une grille
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: 0.75,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: likes.length,
          itemBuilder: (context, index) {
            final videoLike = likes[index];
            final user = videoLike.user;

            return AnimatedLikeGridCard(
              user: user,
              onTap: () => _viewProfile(user),
              index: index,
            );
          },
        );
      },
    );
  }

  Widget _buildLikesSentView() {
    if (_videoLikesSent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun like envoyé',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez à liker des vidéos !',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = ResponsiveHelper.isTablet(context);
        final isDesktop = ResponsiveHelper.isDesktop(context);

        if (isTablet || isDesktop) {
          // Layout tablette/desktop : Liste à gauche, carte à droite
          return Row(
            children: [
              // Liste des likes
              Expanded(
                flex: 1,
                child: _buildLikesSentList(),
              ),
              // Carte avec markers
              Expanded(
                flex: 2,
                child: _buildMap(_videoLikesSent.map((like) => like.user).toList()),
              ),
            ],
          );
        }

        // Layout mobile : Grille simple
        return _buildLikesSentList();
      },
    );
  }

  Widget _buildLikesSentList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = ResponsiveHelper.isTablet(context);
        final isDesktop = ResponsiveHelper.isDesktop(context);

        // En mode tablette/desktop avec carte, afficher une liste verticale compacte
        if ((isTablet || isDesktop) && constraints.maxWidth < 400) {
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _videoLikesSent.length,
            itemBuilder: (context, index) {
              final videoLike = _videoLikesSent[index];
              final user = videoLike.user;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.photoUrlsFull.isNotEmpty
                        ? NetworkImage(user.photoUrlsFull.first)
                        : null,
                    child: user.photoUrlsFull.isEmpty
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${user.age} ans',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => _viewProfile(user),
                ),
              );
            },
          );
        }

        // En mode mobile ou desktop plein écran, afficher une grille
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: 0.75,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _videoLikesSent.length,
          itemBuilder: (context, index) {
            final videoLike = _videoLikesSent[index];
            final user = videoLike.user;

            return AnimatedLikeGridCard(
              user: user,
              onTap: () => _viewProfile(user),
              index: index,
            );
          },
        );
      },
    );
  }

  Widget _buildMap(List<DatingUser> users) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculer le centre et les limites basés sur les positions réelles des utilisateurs
    LatLng center;
    double zoom = 2.0; // Zoom par défaut (vue monde)

    if (users.isEmpty) {
      center = const LatLng(20.0, 0.0); // Vue monde centrée
    } else if (users.length == 1) {
      center = LatLng(users.first.latitude, users.first.longitude);
      zoom = 12.0;
    } else {
      // Calculer le centre moyen
      double avgLat = users.map((u) => u.latitude).reduce((a, b) => a + b) / users.length;
      double avgLng = users.map((u) => u.longitude).reduce((a, b) => a + b) / users.length;
      center = LatLng(avgLat, avgLng);

      // Calculer un zoom approprié basé sur la dispersion des points
      double minLat = users.map((u) => u.latitude).reduce((a, b) => a < b ? a : b);
      double maxLat = users.map((u) => u.latitude).reduce((a, b) => a > b ? a : b);
      double minLng = users.map((u) => u.longitude).reduce((a, b) => a < b ? a : b);
      double maxLng = users.map((u) => u.longitude).reduce((a, b) => a > b ? a : b);

      double latDiff = maxLat - minLat;
      double lngDiff = maxLng - minLng;
      double maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

      // Ajuster le zoom en fonction de la dispersion
      if (maxDiff < 0.01) {
        zoom = 14.0;
      } else if (maxDiff < 0.1) {
        zoom = 12.0;
      } else if (maxDiff < 1.0) {
        zoom = 8.0;
      } else if (maxDiff < 5.0) {
        zoom = 6.0;
      } else if (maxDiff < 20.0) {
        zoom = 4.0;
      } else {
        zoom = 2.0;
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          minZoom: 1.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: isDark
                ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
                : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.dating.app',
          ),
          MarkerLayer(
            markers: users.map((user) {
              return Marker(
                point: LatLng(user.latitude, user.longitude),
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () => _viewProfile(user),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.pink,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: LoadingAnimationWidget.dotsTriangle(color: Colors.pink, size: 60)));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Likes'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.favorite),
              text: 'Reçus (${_videoLikesReceived.length})',
            ),
            Tab(
              icon: const Icon(Icons.send),
              text: 'Envoyés (${_videoLikesSent.length})',
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLikes,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLikesReceivedView(),
            _buildLikesSentView(),
          ],
        ),
      ),
    );
  }
}

