import 'package:flutter/material.dart';
import '../../core/models/dating_user.dart';
import '../../core/models/match_model.dart';
import '../../core/services/backend_service.dart';
import '../../core/utils/page_transitions.dart';
import 'chat_page.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final BackendService _backend = BackendService();

  List<MatchModel> _matches = [];
  Map<String, DatingUser> _matchUsers = {};
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final currentUser = await _backend.getCurrentUser();
      _currentUserId = currentUser is Map ? currentUser['id'] : currentUser.$id;

      print('📊 Chargement des matches pour: $_currentUserId');

      final response = await _backend.getMatches(_currentUserId!);

      print('📊 Response matches: ${response.documents.length} matches');

      final allMatches = (response.documents as List)
          .map((doc) {
            final data = doc is Map ? doc : doc.data;
            print('📊 Match data: $data');
            return MatchModel.fromJson(data);
          })
          .toList();

      print('📊 Total matches avant dédoublonnage: ${allMatches.length}');

      // Dédoublonner les matches par userId (un seul match par utilisateur)
      final Map<String, MatchModel> uniqueMatchesMap = {};
      for (var match in allMatches) {
        final otherUserId = match.getOtherUserId(_currentUserId!);
        // Garder seulement le premier match avec cet utilisateur
        if (!uniqueMatchesMap.containsKey(otherUserId)) {
          uniqueMatchesMap[otherUserId] = match;
        }
      }

      final matches = uniqueMatchesMap.values.toList();
      print('📊 Matches uniques après dédoublonnage: ${matches.length}');

      // Load user info for each unique match
      for (var match in matches) {
        final otherUserId = match.getOtherUserId(_currentUserId!);
        try {
          final userDoc = await _backend.getUserProfile(otherUserId);
          final userData = userDoc is Map ? userDoc : userDoc.data;
          _matchUsers[otherUserId] = DatingUser.fromJson(userData);
        } catch (e) {
          print('⚠️ Erreur chargement utilisateur $otherUserId: $e');
          // Continue if user not found
        }
      }

      if (!mounted) return;
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _openChat(MatchModel match, DatingUser user) {
    context.pushWithSlide(
      ChatPage(
          match: match,
          otherUser: user,
          currentUserId: _currentUserId!,
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Matchs'),
        elevation: 0,
      ),
      body: _matches.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun match pour le moment',
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Continuez à swiper pour trouver des matchs !',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // New matches carousel
                if (_matches.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Nouveaux matchs (${_matches.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _matches.length, // Afficher TOUS les matches
                      physics: const ClampingScrollPhysics(), // Scroll natif
                      clipBehavior: Clip.none,
                      itemBuilder: (context, index) {
                        final match = _matches[index];
                        final otherUserId = match.getOtherUserId(_currentUserId!);
                        final user = _matchUsers[otherUserId];

                        if (user == null) return const SizedBox.shrink();

                        // Vérifier si message non lu
                        final hasUnreadMessage = match.lastMessageSenderId != null &&
                            match.lastMessageSenderId != _currentUserId;

                        return _NewMatchCard(
                          user: user,
                          onTap: () => _openChat(match, user),
                          index: index,
                          hasUnreadMessage: hasUnreadMessage,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Matches list
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Conversations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _matches.length,
                    itemBuilder: (context, index) {
                      final match = _matches[index];
                      final otherUserId = match.getOtherUserId(_currentUserId!);
                      final user = _matchUsers[otherUserId];

                      if (user == null) return const SizedBox.shrink();

                      // Vérifier si message non lu
                      final hasUnreadMessage = match.lastMessageSenderId != null &&
                          match.lastMessageSenderId != _currentUserId;

                      return _MatchListItem(
                        user: user,
                        match: match,
                        onTap: () => _openChat(match, user),
                        index: index,
                        currentUserId: _currentUserId!,
                        hasUnreadMessage: hasUnreadMessage,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _NewMatchCard extends StatefulWidget {
  final DatingUser user;
  final VoidCallback onTap;
  final int index;
  final bool hasUnreadMessage;

  const _NewMatchCard({
    required this.user,
    required this.onTap,
    required this.index,
    this.hasUnreadMessage = false,
  });

  @override
  State<_NewMatchCard> createState() => _NewMatchCardState();
}

class _NewMatchCardState extends State<_NewMatchCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    // Délai basé sur l'index pour effet cascade horizontal
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Hero(
      tag: 'match_${widget.user.id}',
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 100,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.pink, width: 3),
                      image: widget.user.photoUrlsFull.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(widget.user.photoUrlsFull.first),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: widget.user.photoUrlsFull.isEmpty ? Colors.grey[300] : null,
                    ),
                    child: widget.user.photoUrlsFull.isEmpty
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
                  ),
                  // Badge de message non lu
                  if (widget.hasUnreadMessage)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.mail,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.pink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.user.name.split(' ').first,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }
}

class _MatchListItem extends StatefulWidget {
  final DatingUser user;
  final MatchModel match;
  final VoidCallback onTap;
  final int index;
  final String currentUserId;
  final bool hasUnreadMessage;

  const _MatchListItem({
    required this.user,
    required this.match,
    required this.onTap,
    required this.index,
    required this.currentUserId,
    this.hasUnreadMessage = false,
  });

  @override
  State<_MatchListItem> createState() => _MatchListItemState();
}

class _MatchListItemState extends State<_MatchListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    // Délai basé sur l'index pour effet cascade
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Hero(
      tag: 'match_list_${widget.user.id}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
        onTap: widget.onTap,
        contentPadding: const EdgeInsets.all(8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: widget.user.photoUrlsFull.isNotEmpty
                  ? NetworkImage(widget.user.photoUrlsFull.first)
                  : null,
              child: widget.user.photoUrlsFull.isEmpty
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            // Badge de message non lu sur l'avatar
            if (widget.hasUnreadMessage)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          widget.user.name,
          style: TextStyle(
            fontWeight: widget.hasUnreadMessage ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        subtitle: widget.match.lastMessage != null
            ? Text(
                widget.match.lastMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.hasUnreadMessage ? Colors.black87 : Colors.grey[600],
                  fontSize: 13,
                  fontWeight: widget.hasUnreadMessage ? FontWeight.w500 : FontWeight.normal,
                ),
              )
            : Text(
                'Match depuis ${_formatDate(widget.match.createdAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
        trailing: widget.hasUnreadMessage
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Nouveau',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.message, color: Colors.pink, size: 20),
              ),
      ),
      ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}