import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../../core/models/dating_user.dart';
import '../../core/models/video_model.dart';
import '../../core/services/backend_service.dart';
import '../../core/services/cache_service.dart';

class LikesMatchesPanel extends StatefulWidget {
  final VoidCallback? onLikesTap;
  final VoidCallback? onMatchesTap;

  const LikesMatchesPanel({
    super.key,
    this.onLikesTap,
    this.onMatchesTap,
  });

  @override
  State<LikesMatchesPanel> createState() => _LikesMatchesPanelState();
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

class Match {
  final String id;
  final DatingUser user;
  final String createdAt;

  Match({
    required this.id,
    required this.user,
    required this.createdAt,
  });
}

class _LikesMatchesPanelState extends State<LikesMatchesPanel> {
  final BackendService _backend = BackendService();
  List<VideoLike> _videoLikes = [];
  List<Match> _matches = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final currentUser = await _backend.getCurrentUser();
      _currentUserId = currentUser is Map ? currentUser['id'] : currentUser.$id;

      // Charger les likes reçus (limité à 5)
      await _loadLikes();

      // Charger les matches (limité à 5)
      await _loadMatches();

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Erreur chargement panel: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLikes() async {
    try {
      final response = await _backend.getLikesReceived();
      final documents = response is Map ? (response['documents'] ?? []) : response.documents;

      List<VideoLike> videoLikes = [];
      Map<String, VideoLike> uniqueLikes = {};

      for (var doc in documents.take(5)) {
        try {
          final likeData = doc is Map ? doc : doc.data;
          final userId = likeData['userId'];
          final videoId = likeData['videoId'];

          if (uniqueLikes.containsKey(userId)) continue;

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

          uniqueLikes[userId] = like;
        } catch (e) {
          print('❌ Erreur like: $e');
        }
      }

      setState(() => _videoLikes = uniqueLikes.values.toList());
    } catch (e) {
      print('❌ Erreur _loadLikes: $e');
    }
  }

  Future<void> _loadMatches() async {
    try {
      if (_currentUserId == null) return;

      final matchesDoc = await _backend.getMatches(_currentUserId!);
      Map<String, Match> uniqueMatches = {}; // Dédoublonnage par userId

      for (var doc in matchesDoc.documents) {
        try {
          final matchData = doc.data;
          final user1Id = matchData['user1Id'];
          final user2Id = matchData['user2Id'];
          final otherUserId = user1Id == _currentUserId ? user2Id : user1Id;

          // Ignorer si déjà présent (dédoublonnage)
          if (uniqueMatches.containsKey(otherUserId)) continue;

          final userDoc = await _backend.getUserProfile(otherUserId);
          final userData = userDoc is Map ? userDoc : userDoc.data;

          uniqueMatches[otherUserId] = Match(
            id: matchData['\$id'] ?? matchData['id'] ?? '',
            user: DatingUser.fromJson(userData),
            createdAt: matchData['createdAt'] ?? '',
          );

          // Limiter à 5 matches uniques
          if (uniqueMatches.length >= 5) break;
        } catch (e) {
          print('❌ Erreur match: $e');
        }
      }

      setState(() => _matches = uniqueMatches.values.toList());
    } catch (e) {
      print('❌ Erreur _loadMatches: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 1000), // Augmenté pour plus de visibilité
      reverse: false,
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          fillColor: Colors.transparent,
          child: child,
        );
      },
      child: Container(
        key: ValueKey(_isLoading), // Force rebuild pour animer
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Gris foncé au lieu de blanc
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Likes avec animation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Likes reçus',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_videoLikes.isNotEmpty)
                    TextButton(
                      onPressed: widget.onLikesTap,
                      child: const Text('Voir tout'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_videoLikes.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Aucun like reçu', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...(_videoLikes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final like = entry.value;
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 400 + (index * 80)),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(30 * (1 - value), 0),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: _buildLikeCard(like),
                  );
                })),
              const Divider(height: 32),
              // Section Matches avec animation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Matches',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_matches.isNotEmpty)
                    TextButton(
                      onPressed: widget.onMatchesTap,
                      child: const Text('Voir tout'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_matches.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Aucun match', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...(_matches.asMap().entries.map((entry) {
                  final index = entry.key;
                  final match = entry.value;
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 400 + (index * 80)),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(30 * (1 - value), 0),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: _buildMatchCard(match),
                  );
                })),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLikeCard(VideoLike like) {
    final photoUrl = like.user.photoUrlsFull.isNotEmpty ? like.user.photoUrlsFull.first : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      color: const Color(0xFF2A2A2A), // Fond gris foncé pour les cartes
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty ? const Icon(Icons.person, size: 20) : null,
        ),
        title: Text(
          '${like.user.name}, ${like.user.age}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white, // Texte blanc
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: like.user.occupation != null && like.user.occupation!.isNotEmpty
            ? Text(
                like.user.occupation!,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              )
            : null,
        trailing: const Icon(Icons.favorite, color: Colors.pink, size: 20),
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    final photoUrl = match.user.photoUrlsFull.isNotEmpty ? match.user.photoUrlsFull.first : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      color: const Color(0xFF2A2A2A), // Fond gris foncé pour les cartes
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty ? const Icon(Icons.person, size: 20) : null,
        ),
        title: Text(
          '${match.user.name}, ${match.user.age}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white, // Texte blanc
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: match.user.occupation != null && match.user.occupation!.isNotEmpty
            ? Text(
                match.user.occupation!,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              )
            : null,
        trailing: const Icon(Icons.chat, color: Colors.green, size: 20),
        onTap: widget.onMatchesTap,
      ),
    );
  }
}
