import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/models/dating_user.dart';
import '../../core/models/video_model.dart';
import '../../core/services/backend_service.dart';
import '../../core/widgets/web_video_player.dart';
import '../../core/utils/responsive_helper.dart';

/// Carte de profil moderne avec design élégant
class ModernSwipeCard extends StatefulWidget {
  final DatingUser user;
  final VideoModel? video;
  final BackendService backendService;
  final String? currentUserId;
  final bool isVisible;
  final Set<String> likedVideoIds;
  final Set<String> viewedVideoIds;
  final VoidCallback? onSwipeUp;

  const ModernSwipeCard({
    super.key,
    required this.user,
    required this.video,
    required this.backendService,
    this.currentUserId,
    this.isVisible = false,
    required this.likedVideoIds,
    required this.viewedVideoIds,
    this.onSwipeUp,
  });

  @override
  State<ModernSwipeCard> createState() => _ModernSwipeCardState();
}

class _ModernSwipeCardState extends State<ModernSwipeCard> with AutomaticKeepAliveClientMixin {
  final GlobalKey _playerKey = GlobalKey();
  bool _isVideoInitialized = false;
  String? _videoUrl;
  bool _showInfo = false;

  @override
  bool get wantKeepAlive => true;

  bool get _hasLikedVideo => widget.video != null && widget.likedVideoIds.contains(widget.video!.id);

  @override
  void initState() {
    super.initState();

    if (widget.video != null) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(ModernSwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.video?.id != widget.video?.id) {
      setState(() {
        _isVideoInitialized = false;
        _videoUrl = null;
      });
      if (widget.video != null) {
        _initializeVideo();
      }
    }

    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        if (_isVideoInitialized) {
          WebVideoPlayer.setVolume(_playerKey, 1.0);
          WebVideoPlayer.play(_playerKey);
          _incrementViewIfNeeded();
        }
      } else {
        if (_isVideoInitialized) {
          WebVideoPlayer.setVolume(_playerKey, 0.0);
          WebVideoPlayer.pause(_playerKey);
        }
      }
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.video == null) return;

    try {
      final url = await widget.backendService.getVideoUrl(widget.video!.fileId);

      setState(() {
        _videoUrl = url;
        _isVideoInitialized = true;
      });

      print('🎬 Init ${widget.user.name} (visible: ${widget.isVisible}): $url');

      if (widget.isVisible) {
        print('🔊 Carte VISIBLE - Volume 1.0 + Play pour ${widget.user.name}');
        WebVideoPlayer.setVolume(_playerKey, 1.0);
        WebVideoPlayer.play(_playerKey);
        _incrementViewIfNeeded();
      } else {
        print('🔇 Carte INVISIBLE - Volume 0.0 + Pause pour ${widget.user.name}');
        WebVideoPlayer.setVolume(_playerKey, 0.0);
        WebVideoPlayer.pause(_playerKey);
      }
    } catch (e) {
      print('❌ Erreur initialisation vidéo pour ${widget.user.name}: $e');
    }
  }

  Future<void> _incrementViewIfNeeded() async {
    if (widget.video == null) return;
    if (widget.viewedVideoIds.contains(widget.video!.id)) return;

    try {
      print('👁️ Incrémentation vue pour vidéo ${widget.video!.id}');
      final result = await widget.backendService.incrementVideoView(widget.video!.id);

      if (result != null && result['success'] == true) {
        widget.viewedVideoIds.add(widget.video!.id);
        print('✅ Vue incrémentée: ${result['totalViews']} vues');
      }
    } catch (e) {
      print('⚠️ Erreur incrémentation vue: $e');
    }
  }

  @override
  void dispose() {
    print('🗑️ Dispose vidéo pour ${widget.user.name}');
    if (_playerKey.currentState != null) {
      WebVideoPlayer.pause(_playerKey);
      WebVideoPlayer.setVolume(_playerKey, 0.0);
    }
    super.dispose();
  }

  Widget _buildBackground() {
    if (_isVideoInitialized && _videoUrl != null && widget.video != null) {
      return WebVideoPlayer(
        key: _playerKey,
        videoUrl: _videoUrl!,
        autoPlay: widget.isVisible,
        loop: true,
        
      );
    }

    // Photo de profil
    if (widget.user.photoUrls.isNotEmpty) {
      final photoUrl = widget.backendService.getPhotoUrl(widget.user.photoUrls.first);
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.pink.shade300,
            Colors.purple.shade400,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: 100,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -400) {
            widget.onSwipeUp?.call();
          }
        },
        onTap: () {
          setState(() => _showInfo = !_showInfo);
        },
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background (video ou photo)
              _buildBackground(),

              // Gradient overlay moderne
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.4, 0.7, 1.0],
                  ),
                ),
              ),

              // Info principale en bas
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildMainInfo(),
              ),

              // Indicateur swipe up
              Positioned(
                top: MediaQuery.of(context).size.height * 0.4,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildSwipeUpIndicator(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfo() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        bottom: 120.0, // Plus d'espace pour ne pas être caché par la navigation
        top: 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stats compactes (likes, matches, type compte)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Type de compte
              _buildStatChip(
                icon: _getSubscriptionIcon(widget.user.subscriptionPlan),
                label: _getSubscriptionLabel(widget.user.subscriptionPlan),
                color: _getSubscriptionColor(widget.user.subscriptionPlan),
              ),
              _buildStatChip(
                icon: Icons.favorite,
                label: '${widget.user.matchCount ?? 0}',
                color: Colors.pink,
              ),
              _buildStatChip(
                icon: Icons.people,
                label: '${widget.user.likeCount ?? 0}',
                color: Colors.purple,
              ),
              if (widget.video != null)
                _buildStatChip(
                  icon: Icons.visibility,
                  label: '${widget.video!.views}',
                  color: Colors.blue,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Nom et âge
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.user.name}, ${widget.user.age}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.getFontSize(
                      context,
                      mobile: 28,
                      tablet: 32,
                      desktop: 36,
                    ),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    shadows: const [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.user.verified)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Genre et orientation sexuelle
          Row(
            children: [
              if (widget.user.gender.isNotEmpty) ...[
                const Icon(Icons.person, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  widget.user.gender,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (widget.user.sexualOrientation != null && widget.user.sexualOrientation!.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  widget.user.sexualOrientation!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Préférences de recherche
          if (widget.user.lookingFor.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.search, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.user.lookingFor.join(", "),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // Localisation et occupation
          if (widget.user.city != null || widget.user.occupation != null)
            Row(
              children: [
                if (widget.user.city != null) ...[
                  const Icon(Icons.location_on, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    widget.user.city!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (widget.user.city != null && widget.user.occupation != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('•', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ),
                if (widget.user.occupation != null)
                  Expanded(
                    child: Text(
                      widget.user.occupation!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 16),

          // Centres d'intérêt (tags modernes)
          if (widget.user.interests.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.user.interests.take(3).map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    interest,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Helpers pour le type d'abonnement
  IconData _getSubscriptionIcon(String plan) {
    switch (plan.toLowerCase()) {
      case 'gold':
        return Icons.workspace_premium;
      case 'silver':
        return Icons.star;
      default:
        return Icons.person;
    }
  }

  String _getSubscriptionLabel(String plan) {
    switch (plan.toLowerCase()) {
      case 'gold':
        return 'Gold';
      case 'silver':
        return 'Silver';
      default:
        return 'Free';
    }
  }

  Color _getSubscriptionColor(String plan) {
    switch (plan.toLowerCase()) {
      case 'gold':
        return const Color(0xFFFFD700); // Or
      case 'silver':
        return const Color(0xFFC0C0C0); // Argent
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _showInfo = !_showInfo);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(
          _showInfo ? Icons.close : Icons.info_outline,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildDetailedInfo() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.85),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    // Bio
                    if (widget.user.bio.isNotEmpty) ...[
                      _buildInfoSection(
                        'À propos',
                        widget.user.bio,
                        Icons.description,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Détails
                    _buildDetailItem(Icons.cake, 'Âge', '${widget.user.age} ans'),
                    if (widget.user.height != null)
                      _buildDetailItem(Icons.height, 'Taille', '${widget.user.height} cm'),
                    if (widget.user.education != null)
                      _buildDetailItem(Icons.school, 'Éducation', widget.user.education!),
                    if (widget.user.occupation != null)
                      _buildDetailItem(Icons.work, 'Profession', widget.user.occupation!),

                    const SizedBox(height: 24),

                    // Tous les centres d'intérêt
                    if (widget.user.interests.isNotEmpty) ...[
                      const Text(
                        'Centres d\'intérêt',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.user.interests.map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text(
                              interest,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeUpIndicator() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 5),
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, -value),
          child: Opacity(
            opacity: 0.3,
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              color: Colors.white,
              size: 28,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}
