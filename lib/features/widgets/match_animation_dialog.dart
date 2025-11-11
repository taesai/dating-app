import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../../core/models/dating_user.dart';
import '../../core/utils/responsive_helper.dart';

/// Dialog animé spectaculaire pour les matchs
class MatchAnimationDialog extends StatefulWidget {
  final DatingUser user;
  final VoidCallback onContinue;
  final VoidCallback onMessage;

  const MatchAnimationDialog({
    super.key,
    required this.user,
    required this.onContinue,
    required this.onMessage,
  });

  @override
  State<MatchAnimationDialog> createState() => _MatchAnimationDialogState();
}

class _MatchAnimationDialogState extends State<MatchAnimationDialog>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _heartsController;
  late AnimationController _glowController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Animation principale
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Animation des cœurs flottants
    _heartsController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    // Animation de glow pulsant
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _heartsController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: child,
              ),
            ),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Cœurs flottants en arrière-plan
            AnimatedBuilder(
              animation: _heartsController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _FloatingHeartsPainter(
                    progress: _heartsController.value,
                  ),
                  size: const Size(400, 600),
                );
              },
            ),

            // Conteneur principal avec effet glassmorphism
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: ResponsiveHelper.getDialogWidth(context),
                  padding: ResponsiveHelper.getAdaptivePadding(context),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.pink.withOpacity(0.3),
                        Colors.purple.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Grand cœur animé avec glow
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(_glowAnimation.value * 0.8),
                                  blurRadius: 50 * _glowAnimation.value,
                                  spreadRadius: 10 * _glowAnimation.value,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: ResponsiveHelper.getIconSize(
                                context,
                                mobile: 80,
                                tablet: 100,
                                desktop: 120,
                              ),
                              shadows: [
                                Shadow(
                                  color: Colors.pink.withOpacity(0.5),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Texte "C'est un Match!"
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.white, Colors.pink.shade100],
                        ).createShader(bounds),
                        child: Text(
                          'C\'est un Match !',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getFontSize(
                              context,
                              mobile: 32,
                              tablet: 42,
                              desktop: 52,
                            ),
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: const [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: ResponsiveHelper.isMobile(context) ? 12 : 16),

                      // Message
                      Text(
                        'Vous et ${widget.user.name}\nvous aimez mutuellement !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveHelper.getFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Boutons
                      Row(
                        children: [
                          Expanded(
                            child: _AnimatedButton(
                              onPressed: widget.onContinue,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              textColor: Colors.white,
                              text: 'Continuer',
                              icon: Icons.close,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _AnimatedButton(
                              onPressed: widget.onMessage,
                              backgroundColor: Colors.white,
                              textColor: Colors.pink,
                              text: 'Message',
                              icon: Icons.message,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter pour les cœurs flottants
class _FloatingHeartsPainter extends CustomPainter {
  final double progress;
  final math.Random _random = math.Random(42); // Seed fixe pour cohérence

  _FloatingHeartsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 20; i++) {
      final x = _random.nextDouble() * size.width;
      final baseY = size.height * _random.nextDouble();
      final speed = 0.3 + _random.nextDouble() * 0.5;
      final y = baseY - (progress * size.height * speed) % size.height;
      final heartSize = 15 + _random.nextDouble() * 25;
      final opacity = (0.3 + _random.nextDouble() * 0.4);

      _drawHeart(
        canvas,
        Offset(x, y),
        heartSize,
        Colors.white.withOpacity(opacity),
      );
    }
  }

  void _drawHeart(Canvas canvas, Offset position, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    canvas.save();
    canvas.translate(position.dx, position.dy);

    path.moveTo(0, size * 0.3);
    path.cubicTo(-size * 0.6, -size * 0.2, -size * 0.6, size * 0.4, 0, size * 0.8);
    path.cubicTo(size * 0.6, size * 0.4, size * 0.6, -size * 0.2, 0, size * 0.3);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FloatingHeartsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Bouton animé pour le dialog
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final String text;
  final IconData icon;

  const _AnimatedButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    required this.text,
    required this.icon,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onPressed();
          },
          onTapCancel: () => _controller.reverse(),
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.textColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
