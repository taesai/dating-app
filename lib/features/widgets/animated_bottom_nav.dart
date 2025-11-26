import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

/// Barre de navigation animée avec effets modernes
class AnimatedBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int likesCount;
  final int matchesCount;
  final int messagesCount;

  const AnimatedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.likesCount,
    required this.matchesCount,
    this.messagesCount = 0,
  });

  @override
  State<AnimatedBottomNav> createState() => _AnimatedBottomNavState();
}

class _AnimatedBottomNavState extends State<AnimatedBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _previousIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(AnimatedBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8EDF2);

    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: isDark
            ? [
                // Mode sombre - ombres plus subtiles
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.03),
                  offset: const Offset(0, -1),
                  blurRadius: 2,
                  spreadRadius: 0,
                ),
              ]
            : [
                // Mode clair - ombres neumorphiques
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  offset: const Offset(0, -2),
                  blurRadius: 6,
                  spreadRadius: -1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  offset: const Offset(0, -4),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  offset: const Offset(0, -1),
                  blurRadius: 2,
                  spreadRadius: 0,
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.local_fire_department,
              label: 'Découvrir',
              index: 0,
              currentIndex: widget.currentIndex,
              onTap: () => widget.onTap(0),
              controller: _controller,
              badgeCount: 0,
            ),
            _NavItem(
              icon: Icons.favorite_border,
              label: 'Likes',
              index: 1,
              currentIndex: widget.currentIndex,
              onTap: () => widget.onTap(1),
              controller: _controller,
              badgeCount: widget.likesCount,
              badgeColor: Colors.red,
            ),
            _NavItem(
              icon: Icons.map,
              label: 'Carte',
              index: 2,
              currentIndex: widget.currentIndex,
              onTap: () => widget.onTap(2),
              controller: _controller,
              badgeCount: 0,
            ),
            _NavItem(
              icon: Icons.celebration,
              label: 'Matchs',
              index: 3,
              currentIndex: widget.currentIndex,
              onTap: () => widget.onTap(3),
              controller: _controller,
              badgeCount: widget.matchesCount + widget.messagesCount,
              badgeColor: widget.messagesCount > 0 ? Colors.blue : Colors.pink,
            ),
            _NavItem(
              icon: Icons.person,
              label: 'Profil',
              index: 4,
              currentIndex: widget.currentIndex,
              onTap: () => widget.onTap(4),
              controller: _controller,
              badgeCount: 0,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;
  final AnimationController controller;
  final int badgeCount;
  final Color? badgeColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.controller,
    required this.badgeCount,
    this.badgeColor,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Pulse animation for badges
    if (widget.badgeCount > 0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.badgeCount > 0 && oldWidget.badgeCount == 0) {
      _pulseController.repeat(reverse: true);
    } else if (widget.badgeCount == 0 && oldWidget.badgeCount > 0) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.index == widget.currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8EDF2);
    final iconColor = isSelected
        ? (isDark ? const Color(0xFFFF4081) : Colors.pink)
        : (isDark ? Colors.grey[400] : Colors.grey[600]);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) {
          final scale = isSelected
              ? 1.0 + (0.15 * widget.controller.value)
              : 1.0 - (0.05 * widget.controller.value);

          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Icon with animated glow
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: backgroundColor,
                      boxShadow: isDark
                          ? (isSelected
                              ? [
                                  // Mode sombre - enfoncé
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    offset: const Offset(2, 2),
                                    blurRadius: 4,
                                    spreadRadius: -1,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.05),
                                    offset: const Offset(-1, -1),
                                    blurRadius: 3,
                                    spreadRadius: -1,
                                  ),
                                ]
                              : [
                                  // Mode sombre - surélevé
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.05),
                                    offset: const Offset(-2, -2),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    offset: const Offset(2, 2),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ])
                          : (isSelected
                              ? [
                                  // Mode clair - enfoncé
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(2, 2),
                                    blurRadius: 4,
                                    spreadRadius: -2,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.7),
                                    offset: const Offset(-2, -2),
                                    blurRadius: 4,
                                    spreadRadius: -2,
                                  ),
                                ]
                              : [
                                  // Mode clair - surélevé
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.8),
                                    offset: const Offset(-3, -3),
                                    blurRadius: 6,
                                    spreadRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    offset: const Offset(3, 3),
                                    blurRadius: 6,
                                    spreadRadius: 0,
                                  ),
                                ]),
                    ),
                    child: Icon(
                      widget.icon,
                      color: iconColor,
                      size: 26,
                    ),
                  ),

                  // Badge with pulse animation
                  if (widget.badgeCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: widget.badgeColor ?? Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: (widget.badgeColor ?? Colors.red)
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Center(
                                child: Text(
                                  widget.badgeCount > 99
                                      ? '99+'
                                      : widget.badgeCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: isSelected ? 12 : 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? (isDark ? const Color(0xFFFF4081) : Colors.pink)
                      : (isDark ? Colors.grey[400] : Colors.grey[700]),
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
