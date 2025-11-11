import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Type de swipe
enum SwipeDirection { left, right, up }

/// Overlay de feedback visuel pendant le swipe
class SwipeFeedbackOverlay extends StatelessWidget {
  final double swipeProgress; // 0.0 à 1.0
  final SwipeDirection? direction;

  const SwipeFeedbackOverlay({
    super.key,
    required this.swipeProgress,
    this.direction,
  });

  @override
  Widget build(BuildContext context) {
    if (direction == null || swipeProgress < 0.1) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Stack(
        children: [
          // Gradient overlay basé sur la direction
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              gradient: _getGradient(),
            ),
          ),

          // Icône et texte
          Center(
            child: Transform.scale(
              scale: 0.8 + (swipeProgress * 0.4),
              child: Transform.rotate(
                angle: direction == SwipeDirection.left
                    ? -0.2 * swipeProgress
                    : (direction == SwipeDirection.right ? 0.2 * swipeProgress : 0),
                child: _buildFeedbackWidget(),
              ),
            ),
          ),

          // Particules
          if (swipeProgress > 0.5)
            _ParticlesLayer(
              progress: swipeProgress,
              direction: direction!,
            ),
        ],
      ),
    );
  }

  LinearGradient? _getGradient() {
    Color color;
    switch (direction!) {
      case SwipeDirection.left:
        color = Colors.red;
        break;
      case SwipeDirection.right:
        color = Colors.green;
        break;
      case SwipeDirection.up:
        color = Colors.blue;
        break;
    }

    return LinearGradient(
      begin: Alignment.center,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.0),
        color.withOpacity(swipeProgress * 0.3),
      ],
    );
  }

  Widget _buildFeedbackWidget() {
    IconData icon;
    String text;
    Color color;

    switch (direction!) {
      case SwipeDirection.left:
        icon = Icons.close;
        text = 'NOPE';
        color = Colors.red;
        break;
      case SwipeDirection.right:
        icon = Icons.favorite;
        text = 'LIKE';
        color = Colors.green;
        break;
      case SwipeDirection.up:
        icon = Icons.star;
        text = 'SUPER LIKE';
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
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
          Icon(icon, color: Colors.white, size: 40),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Layer de particules animées
class _ParticlesLayer extends StatefulWidget {
  final double progress;
  final SwipeDirection direction;

  const _ParticlesLayer({
    required this.progress,
    required this.direction,
  });

  @override
  State<_ParticlesLayer> createState() => _ParticlesLayerState();
}

class _ParticlesLayerState extends State<_ParticlesLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlesPainter(
            progress: _controller.value,
            swipeProgress: widget.progress,
            direction: widget.direction,
          ),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

/// Painter pour les particules
class _ParticlesPainter extends CustomPainter {
  final double progress;
  final double swipeProgress;
  final SwipeDirection direction;
  final math.Random _random = math.Random(42);

  _ParticlesPainter({
    required this.progress,
    required this.swipeProgress,
    required this.direction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final particleCount = (swipeProgress * 20).toInt();
    Color color;

    switch (direction) {
      case SwipeDirection.left:
        color = Colors.red;
        break;
      case SwipeDirection.right:
        color = Colors.green;
        break;
      case SwipeDirection.up:
        color = Colors.blue;
        break;
    }

    for (int i = 0; i < particleCount; i++) {
      final particleProgress = (progress + (i * 0.1)) % 1.0;
      final x = _random.nextDouble() * size.width;
      final y = size.height - (particleProgress * size.height);
      final opacity = (1 - particleProgress) * swipeProgress;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      // Dessiner des petits cœurs ou étoiles selon la direction
      if (direction == SwipeDirection.right) {
        _drawHeart(canvas, Offset(x, y), 15, paint);
      } else {
        canvas.drawCircle(Offset(x, y), 8, paint);
      }
    }
  }

  void _drawHeart(Canvas canvas, Offset position, double size, Paint paint) {
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
  bool shouldRepaint(_ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.swipeProgress != swipeProgress;
  }
}

/// Widget qui encapsule une carte avec feedback de swipe
class SwipeableCardWithFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final double threshold;

  const SwipeableCardWithFeedback({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.threshold = 100,
  });

  @override
  State<SwipeableCardWithFeedback> createState() => _SwipeableCardWithFeedbackState();
}

class _SwipeableCardWithFeedbackState extends State<SwipeableCardWithFeedback>
    with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  double _rotation = 0;
  SwipeDirection? _currentDirection;
  double _swipeProgress = 0;

  late AnimationController _resetController;
  late Animation<Offset> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _resetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
      _rotation = _position.dx / 1000;

      // Calculer la direction et le progrès
      final absX = _position.dx.abs();
      final absY = _position.dy.abs();

      if (absY > absX && _position.dy < 0) {
        _currentDirection = SwipeDirection.up;
        _swipeProgress = (absY / widget.threshold).clamp(0.0, 1.0);
      } else if (_position.dx > 0) {
        _currentDirection = SwipeDirection.right;
        _swipeProgress = (absX / widget.threshold).clamp(0.0, 1.0);
      } else if (_position.dx < 0) {
        _currentDirection = SwipeDirection.left;
        _swipeProgress = (absX / widget.threshold).clamp(0.0, 1.0);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final absX = _position.dx.abs();
    final absY = _position.dy.abs();

    // Vérifier si le swipe est assez fort
    if (absY > widget.threshold && _position.dy < 0) {
      widget.onSwipeUp?.call();
    } else if (absX > widget.threshold) {
      if (_position.dx > 0) {
        widget.onSwipeRight?.call();
      } else {
        widget.onSwipeLeft?.call();
      }
    }

    // Reset position
    _resetAnimation = Tween<Offset>(
      begin: _position,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
    );

    _resetController.forward(from: 0).then((_) {
      setState(() {
        _position = Offset.zero;
        _rotation = 0;
        _currentDirection = null;
        _swipeProgress = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _resetController,
        builder: (context, child) {
          final currentPos = _resetController.isAnimating
              ? _resetAnimation.value
              : _position;

          return Transform.translate(
            offset: currentPos,
            child: Transform.rotate(
              angle: _rotation,
              child: Stack(
                children: [
                  widget.child,
                  SwipeFeedbackOverlay(
                    swipeProgress: _swipeProgress,
                    direction: _currentDirection,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
