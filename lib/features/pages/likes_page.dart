import 'package:flutter/material.dart';
import '../../core/models/dating_user.dart';
import '../../core/models/video_model.dart';
import '../../core/services/backend_service.dart';
import '../../core/utils/page_transitions.dart';
import '../widgets/animated_like_card.dart';
import 'dating_home_page.dart';
import 'user_detail_profile_page.dart';

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

      for (var doc in documents) {
        try {
          final likeData = doc is Map ? doc : doc.data;
          final userId = likeData['userId'];
          final videoId = likeData['videoId'];

          // Si cet utilisateur a déjà liké une autre vidéo, on ignore ce like
          if (uniqueLikes.containsKey(userId)) {
            print('⏭️ Like ignoré (doublon): userId=$userId déjà présent');
            continue;
          }

          print('👤 Chargement like reçu: userId=$userId, videoId=$videoId');

          // Charger les données complètes de l'utilisateur et de la vidéo
          final userDoc = await _backend.getUserProfile(userId);
          final videoDoc = await _backend.getVideo(videoId);

          final userData = userDoc is Map ? userDoc : userDoc.data;
          final videoData = videoDoc is Map ? videoDoc : videoDoc.data;

          final like = VideoLike(
            id: likeData['\$id'] ?? likeData['id'] ?? '',
            user: DatingUser.fromJson(userData),
            video: VideoModel.fromJson(videoData),
            createdAt: likeData['createdAt'] ?? '',
          );

          // Stocker dans la map pour dédoublonner
          uniqueLikes[userId] = like;

          print('✅ Like reçu chargé: ${DatingUser.fromJson(userData).name}');
        } catch (e) {
          print('❌ Erreur chargement like reçu: $e');
        }
      }

      // Convertir la map en liste
      videoLikes = uniqueLikes.values.toList();

      if (!mounted) return;
      setState(() {
        _videoLikesReceived = videoLikes;
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

      for (var doc in documents) {
        try {
          final likeData = doc is Map ? doc : doc.data;
          final videoId = likeData['videoId'];

          // Charger la vidéo pour obtenir l'userId du propriétaire
          final videoDoc = await _backend.getVideo(videoId);
          final videoData = videoDoc is Map ? videoDoc : videoDoc.data;
          final video = VideoModel.fromJson(videoData);

          final userId = video.userId;

          // Si on a déjà un like pour cet utilisateur, on ignore
          if (uniqueLikes.containsKey(userId)) {
            print('⏭️ Like ignoré (doublon): userId=$userId déjà présent');
            continue;
          }

          print('👤 Chargement like envoyé: userId=$userId, videoId=$videoId');

          // Charger les données complètes de l'utilisateur
          final userDoc = await _backend.getUserProfile(userId);
          final userData = userDoc is Map ? userDoc : userDoc.data;

          final like = VideoLike(
            id: likeData['\$id'] ?? likeData['id'] ?? '',
            user: DatingUser.fromJson(userData),
            video: video,
            createdAt: likeData['createdAt'] ?? '',
          );

          // Stocker dans la map pour dédoublonner
          uniqueLikes[userId] = like;

          print('✅ Like envoyé chargé: ${DatingUser.fromJson(userData).name}');
        } catch (e) {
          print('❌ Erreur chargement like envoyé: $e');
        }
      }

      // Convertir la map en liste
      videoLikes = uniqueLikes.values.toList();

      if (!mounted) return;
      setState(() {
        _videoLikesSent = videoLikes;
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

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _videoLikesReceived.length,
      itemBuilder: (context, index) {
        final videoLike = _videoLikesReceived[index];
        final user = videoLike.user;

        return AnimatedLikeGridCard(
          user: user,
          onTap: () => _viewProfile(user),
          index: index,
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

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
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
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

