import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../core/widgets/rive_loader.dart';
import 'package:latlong2/latlong.dart';
import '../../core/models/dating_user.dart';
import '../../core/models/match_model.dart';
import '../../core/services/backend_service.dart';
import '../../core/utils/page_transitions.dart';
import '../../core/utils/responsive_helper.dart';
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
  Set<String> _viewedMatchIds = {}; // Tracker les matches consultés
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

      // Charger TOUS les profils utilisateurs en PARALLÈLE
      print('👥 Chargement de ${matches.length} profils en parallèle...');
      final userFutures = matches.map((match) async {
        final otherUserId = match.getOtherUserId(_currentUserId!);
        try {
          final userDoc = await _backend.getUserProfile(otherUserId);
          final userData = userDoc is Map ? userDoc : userDoc.data;
          return MapEntry(otherUserId, DatingUser.fromJson(userData));
        } catch (e) {
          print('⚠️ Erreur chargement utilisateur $otherUserId: $e');
          return null;
        }
      }).toList();

      final userResults = await Future.wait(userFutures);

      // Stocker les résultats
      for (var entry in userResults) {
        if (entry != null) {
          _matchUsers[entry.key] = entry.value;
        }
      }

      print('✅ ${_matchUsers.length} profils chargés');

      // Filtrer les matches pour ne garder que ceux avec des profils valides
      final validMatches = matches.where((match) {
        final otherUserId = match.getOtherUserId(_currentUserId!);
        return _matchUsers.containsKey(otherUserId);
      }).toList();

      print('✅ ${validMatches.length} matches valides sur ${matches.length} au total');

      if (!mounted) return;
      setState(() {
        _matches = validMatches;
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

  Future<void> _openChat(MatchModel match, DatingUser user) async {
    // Marquer ce match comme consulté
    setState(() {
      _viewedMatchIds.add(match.id);
    });

    // Ouvrir le chat
    await context.pushWithSlide(
      ChatPage(
          match: match,
          otherUser: user,
          currentUserId: _currentUserId!,
        ),
    );
  }

  /// Construit la carte avec les markers des matches
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
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    // Trouver le match correspondant
                    final match = _matches.firstWhere(
                      (m) => m.getOtherUserId(_currentUserId!) == user.id,
                    );
                    _openChat(match, user);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.purple,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.5),
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
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Construit la liste des matches
  Widget _buildMatchesList() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
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
              match.lastMessageSenderId != _currentUserId &&
              !_viewedMatchIds.contains(match.id);

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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: RiveLoader()));
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
                    height: 110, // Réduit de 140 à 110
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

                        // Vérifier si message non lu (dernier message de l'autre + pas encore consulté)
                        final hasUnreadMessage = match.lastMessageSenderId != null &&
                            match.lastMessageSenderId != _currentUserId &&
                            !_viewedMatchIds.contains(match.id);

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

                // Matches list with responsive layout
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isTablet = ResponsiveHelper.isTablet(context);
                      final isDesktop = ResponsiveHelper.isDesktop(context);

                      if (isTablet || isDesktop) {
                        // Desktop/Tablet: Liste + Carte
                        final matchedUsers = _matches
                            .map((match) => _matchUsers[match.getOtherUserId(_currentUserId!)])
                            .where((user) => user != null)
                            .cast<DatingUser>()
                            .toList();

                        return Row(
                          children: [
                            // Liste des matches (1/3)
                            Expanded(
                              flex: 1,
                              child: _buildMatchesList(),
                            ),
                            // Carte avec markers (2/3)
                            Expanded(
                              flex: 2,
                              child: _buildMap(matchedUsers),
                            ),
                          ],
                        );
                      }

                      // Mobile: Liste uniquement
                      return _buildMatchesList();
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
          width: 80, // Réduit de 100 à 80
          margin: const EdgeInsets.only(right: 10), // Réduit de 12 à 10
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 80, // Réduit de 100 à 80
                    height: 80, // Réduit de 100 à 80
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.pink, width: 2), // Réduit de 3 à 2
                      image: widget.user.photoUrlsFull.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(widget.user.photoUrlsFull.first),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: widget.user.photoUrlsFull.isEmpty ? Colors.grey[300] : null,
                    ),
                    child: widget.user.photoUrlsFull.isEmpty
                        ? const Icon(Icons.person, size: 32, color: Colors.grey) // Réduit de 40 à 32
                        : null,
                  ),
                  // Badge de message non lu
                  if (widget.hasUnreadMessage)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 20, // Réduit de 24 à 20
                        height: 20, // Réduit de 24 à 20
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white, // Texte en blanc
              ),
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
            color: Colors.white, // Texte en blanc
          ),
        ),
        subtitle: widget.match.lastMessage != null
            ? Text(
                widget.match.lastMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.hasUnreadMessage ? Colors.white70 : Colors.grey[400], // Texte en blanc transparent
                  fontSize: 13,
                  fontWeight: widget.hasUnreadMessage ? FontWeight.w500 : FontWeight.normal,
                ),
              )
            : Text(
                'Match depuis ${_formatDate(widget.match.createdAt)}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12), // Texte en gris clair
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