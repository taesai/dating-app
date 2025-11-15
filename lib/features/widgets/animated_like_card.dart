import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/models/dating_user.dart';
import '../../core/services/backend_service.dart';

/// Carte de like animée pour la grille
class AnimatedLikeGridCard extends StatefulWidget {
  final DatingUser user;
  final VoidCallback onTap;
  final int index;

  const AnimatedLikeGridCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.index,
  });

  @override
  State<AnimatedLikeGridCard> createState() => _AnimatedLikeGridCardState();
}

class _AnimatedLikeGridCardState extends State<AnimatedLikeGridCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 400 + (widget.index * 50)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Démarrer l'animation avec un léger délai basé sur l'index
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = BackendService();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Hero(
          tag: 'like_${widget.user.id}',
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo de profil
                  if (widget.user.photoUrlsFull.isNotEmpty)
                    Image.network(
                      widget.user.photoUrlsFull.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),

                  // Icône coeur animée
                  Positioned(
                    top: 8,
                    right: 8,
                    child: TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.8, end: 1.2),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      builder: (context, double scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.pink,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.5),
                                  blurRadius: 10,
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
                        );
                      },
                      onEnd: () {
                        if (mounted) setState(() {});
                      },
                    ),
                  ),

                  // Nom et âge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.user.name}, ${widget.user.age}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.user.city != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.user.city!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.pink.shade300, Colors.purple.shade400],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: 60,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}

/// Carte de like animée pour la liste
class AnimatedLikeListCard extends StatefulWidget {
  final DatingUser user;
  final VoidCallback onTap;
  final int index;

  const AnimatedLikeListCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.index,
  });

  @override
  State<AnimatedLikeListCard> createState() => _AnimatedLikeListCardState();
}

class _AnimatedLikeListCardState extends State<AnimatedLikeListCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          color: const Color(0xFF2A2A2A), // Fond gris foncé
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // Photo de profil (plus petite)
                  Hero(
                    tag: 'like_${widget.user.id}',
                    child: Container(
                      width: 56, // Réduit de 80 à 56
                      height: 56, // Réduit de 80 à 56
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8), // Réduit de 12 à 8
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.2), // Réduit opacité
                            blurRadius: 4, // Réduit de 8 à 4
                            spreadRadius: 0.5, // Réduit de 1 à 0.5
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.user.photoUrlsFull.isNotEmpty
                            ? Image.network(
                                widget.user.photoUrlsFull.first,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.pink.shade300, Colors.purple.shade400],
                                  ),
                                ),
                                child: const Icon(Icons.person, color: Colors.white, size: 28), // Réduit de 40 à 28
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12), // Réduit de 16 à 12

                  // Informations (simplifiées)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.user.name}, ${widget.user.age}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Texte blanc
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Une seule ligne d'info (city OU occupation)
                        if (widget.user.city != null || widget.user.occupation != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.user.city ?? widget.user.occupation ?? '',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Icône like (simplifiée)
                  const Icon(
                    Icons.favorite,
                    color: Colors.pink,
                    size: 22, // Réduit de 24 à 22
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
