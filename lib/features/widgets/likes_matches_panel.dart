import 'package:flutter/material.dart';
import '../../core/models/dating_user.dart';
import '../../core/models/video_model.dart';
import '../../core/services/backend_service.dart';

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
      List<Match> matches = [];

      for (var doc in matchesDoc.documents.take(5)) {
        try {
          final matchData = doc.data;
          final user1Id = matchData['user1Id'];
          final user2Id = matchData['user2Id'];
          final otherUserId = user1Id == _currentUserId ? user2Id : user1Id;

          final userDoc = await _backend.getUserProfile(otherUserId);
          final userData = userDoc is Map ? userDoc : userDoc.data;

          matches.add(Match(
            id: matchData['\$id'] ?? matchData['id'] ?? '',
            user: DatingUser.fromJson(userData),
            createdAt: matchData['createdAt'] ?? '',
          ));
        } catch (e) {
          print('❌ Erreur match: $e');
        }
      }

      setState(() => _matches = matches);
    } catch (e) {
      print('❌ Erreur _loadMatches: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            // Section Likes
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
              ...(_videoLikes.map((like) => _buildLikeCard(like))),
            const Divider(height: 32),
            // Section Matches
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
              ...(_matches.map((match) => _buildMatchCard(match))),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeCard(VideoLike like) {
    final photoUrl = like.user.photoUrlsFull.isNotEmpty ? like.user.photoUrlsFull.first : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${like.user.name}, ${like.user.age}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (like.user.verified) const Icon(Icons.verified, color: Colors.blue, size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (like.user.occupation != null && like.user.occupation!.isNotEmpty)
              Text('💼 ${like.user.occupation}', style: const TextStyle(fontSize: 12)),
            if (like.user.interests.isNotEmpty)
              Text(
                like.user.interests.take(2).join(' • '),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: const Icon(Icons.favorite, color: Colors.pink),
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    final photoUrl = match.user.photoUrlsFull.isNotEmpty ? match.user.photoUrlsFull.first : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${match.user.name}, ${match.user.age}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (match.user.verified) const Icon(Icons.verified, color: Colors.blue, size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (match.user.occupation != null && match.user.occupation!.isNotEmpty)
              Text('💼 ${match.user.occupation}', style: const TextStyle(fontSize: 12)),
            if (match.user.interests.isNotEmpty)
              Text(
                match.user.interests.take(2).join(' • '),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: const Icon(Icons.favorite, color: Colors.pink),
      ),
    );
  }
}
