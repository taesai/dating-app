import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Boutons d'action modernes pour le swipe (Like, Pass, Super Like)
class SwipeActionButtons extends StatelessWidget {
  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final VoidCallback? onSuperLike;
  final VoidCallback? onRewind;

  const SwipeActionButtons({
    super.key,
    this.onPass,
    this.onLike,
    this.onSuperLike,
    this.onRewind,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bouton Rewind (optionnel)
          if (onRewind != null)
            _ModernActionButton(
              icon: Icons.replay,
              size: 50,
              color: Colors.amber,
              onTap: onRewind,
            ),

          // Bouton Pass (X)
          _ModernActionButton(
            icon: Icons.close,
            size: 60,
            color: Colors.red,
            onTap: onPass,
            shadowColor: Colors.red,
          ),

          // Bouton Super Like (Star)
          _ModernActionButton(
            icon: Icons.star,
            size: 55,
            color: Colors.blue,
            onTap: onSuperLike,
            shadowColor: Colors.blue,
          ),

          // Bouton Like (Heart)
          _ModernActionButton(
            icon: Icons.favorite,
            size: 60,
            color: Colors.green,
            onTap: onLike,
            shadowColor: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _ModernActionButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback? onTap;
  final Color? shadowColor;

  const _ModernActionButton({
    required this.icon,
    required this.size,
    required this.color,
    this.onTap,
    this.shadowColor,
  });

  @override
  State<_ModernActionButton> createState() => _ModernActionButtonState();
}

class _ModernActionButtonState extends State<_ModernActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: (widget.shadowColor ?? widget.color).withOpacity(_isPressed ? 0.4 : 0.2),
                    blurRadius: _isPressed ? 15 : 10,
                    spreadRadius: _isPressed ? 3 : 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: widget.size * 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Indicateur de swipe overlay (quand l'utilisateur commence à swiper)
class SwipeOverlayIndicator extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  final double opacity;
  final bool isLeft;

  const SwipeOverlayIndicator({
    super.key,
    required this.text,
    required this.color,
    required this.icon,
    required this.opacity,
    this.isLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      left: isLeft ? 40 : null,
      right: isLeft ? null : 40,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: isLeft ? -0.3 : 0.3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton flottant moderne avec effet de pulsation
class FloatingModernButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final String? tooltip;

  const FloatingModernButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.tooltip,
  });

  @override
  State<FloatingModernButton> createState() => _FloatingModernButtonState();
}

class _FloatingModernButtonState extends State<FloatingModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.color != null
                      ? [widget.color!, widget.color!.withOpacity(0.7)]
                      : [Colors.pink, Colors.purple],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.color ?? Colors.pink).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }
}
