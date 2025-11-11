import 'package:flutter/material.dart';

/// Bouton neumorphic simple sans dépendances externes
/// Couleur gris clair avec ombres pour effet 3D
class SimpleNeumorphicButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const SimpleNeumorphicButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 56,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<SimpleNeumorphicButton> createState() => _SimpleNeumorphicButtonState();
}

class _SimpleNeumorphicButtonState extends State<SimpleNeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ??
        (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E5EC));
    final iColor = widget.iconColor ??
        (isDark ? const Color(0xFFFF4081) : Colors.purple);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          // Bordure pour mieux délimiter le bouton
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isDark
              ? (_isPressed
                  ? [
                      // Mode sombre - enfoncé (ombres inversées)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.8),
                        offset: const Offset(3, 3),
                        blurRadius: 6,
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.08),
                        offset: const Offset(-2, -2),
                        blurRadius: 4,
                        spreadRadius: -2,
                      ),
                    ]
                  : [
                      // Mode sombre - surélevé (ombres très marquées)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.9),
                        offset: const Offset(6, 6),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        offset: const Offset(4, 4),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.08),
                        offset: const Offset(-3, -3),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        offset: const Offset(-1, -1),
                        blurRadius: 3,
                        spreadRadius: 0,
                      ),
                    ])
              : (_isPressed
                  ? [
                      // Mode clair - enfoncé
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: const Offset(3, 3),
                        blurRadius: 6,
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.9),
                        offset: const Offset(-2, -2),
                        blurRadius: 4,
                        spreadRadius: -2,
                      ),
                    ]
                  : [
                      // Mode clair - surélevé
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: const Offset(6, 6),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(4, 4),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(1.0),
                        offset: const Offset(-4, -4),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.7),
                        offset: const Offset(-2, -2),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ]),
        ),
        child: Icon(
          widget.icon,
          size: widget.size * 0.5,
          color: iColor,
        ),
      ),
    );
  }
}
