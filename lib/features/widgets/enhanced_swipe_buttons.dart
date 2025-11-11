import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/utils/responsive_helper.dart';

/// Boutons de swipe améliorés avec micro-interactions
class EnhancedSwipeButtons extends StatelessWidget {
  final VoidCallback onDislike;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;
  final bool isLikeDisabled;

  const EnhancedSwipeButtons({
    super.key,
    required this.onDislike,
    required this.onSuperLike,
    required this.onLike,
    this.isLikeDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    // Tailles responsives des boutons
    final dislikeSize = ResponsiveHelper.getButtonSize(
      context,
      mobile: 55,
      tablet: 65,
      desktop: 70,
    );
    final superLikeSize = ResponsiveHelper.getButtonSize(
      context,
      mobile: 50,
      tablet: 60,
      desktop: 65,
    );
    final likeSize = ResponsiveHelper.getButtonSize(
      context,
      mobile: 65,
      tablet: 75,
      desktop: 85,
    );
    final spacing = ResponsiveHelper.isMobile(context) ? 16.0 : 24.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SwipeButton(
          icon: Icons.close,
          color: Colors.red,
          size: dislikeSize,
          onTap: onDislike,
          tooltip: 'Passer',
        ),
        SizedBox(width: spacing),
        _SwipeButton(
          icon: Icons.star,
          color: Colors.blue,
          size: superLikeSize,
          onTap: onSuperLike,
          tooltip: 'Super Like',
        ),
        SizedBox(width: spacing),
        _SwipeButton(
          icon: Icons.favorite,
          color: Colors.pink,
          size: likeSize,
          onTap: isLikeDisabled ? () {} : onLike,
          tooltip: 'Liker',
          isDisabled: isLikeDisabled,
        ),
      ],
    );
  }
}

/// Bouton de swipe individuel avec animations
class _SwipeButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final String tooltip;
  final bool isDisabled;

  const _SwipeButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    required this.tooltip,
    this.isDisabled = false,
  });

  @override
  State<_SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<_SwipeButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _rippleController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    setState(() => _isPressed = true);
    _scaleController.forward();
    _rippleController.forward(from: 0);
  }

  void _handleTapUp() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.isDisabled
        ? Colors.grey
        : widget.color;

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: widget.isDisabled ? null : (_) => _handleTapDown(),
        onTapUp: widget.isDisabled ? null : (_) => _handleTapUp(),
        onTapCancel: widget.isDisabled ? null : _handleTapCancel,
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleController, _pulseController]),
          builder: (context, child) {
            final scale = _scaleAnimation.value;
            final pulse = _isPressed ? 1.0 : _pulseAnimation.value;

            return Transform.scale(
              scale: scale * pulse,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ripple effect
                  AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, child) {
                      return Container(
                        width: widget.size * (1 + _rippleController.value),
                        height: widget.size * (1 + _rippleController.value),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: effectiveColor.withOpacity(
                              0.5 * (1 - _rippleController.value),
                            ),
                            width: 3,
                          ),
                        ),
                      );
                    },
                  ),

                  // Bouton principal
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      gradient: widget.isDisabled
                          ? LinearGradient(
                              colors: [Colors.grey.shade400, Colors.grey.shade500],
                            )
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                effectiveColor,
                                effectiveColor.withOpacity(0.8),
                              ],
                            ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: effectiveColor.withOpacity(_isPressed ? 0.6 : 0.4),
                          blurRadius: _isPressed ? 20 : 25,
                          spreadRadius: _isPressed ? 2 : 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: widget.size * 0.5,
                    ),
                  ),

                  // Shine effect
                  if (!widget.isDisabled)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _ShinePainter(
                              progress: _pulseController.value,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Painter pour l'effet de brillance
class _ShinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ShinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final shineAngle = progress * 2 * math.pi;
    final shineOffset = Offset(
      math.cos(shineAngle) * radius * 0.3,
      math.sin(shineAngle) * radius * 0.3,
    );

    canvas.drawCircle(
      center + shineOffset,
      radius * 0.3,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Bouton compact pour les actions secondaires
class CompactActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const CompactActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<CompactActionButton> createState() => _CompactActionButtonState();
}

class _CompactActionButtonState extends State<CompactActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
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
            widget.onTap();
          },
          onTapCancel: () => _controller.reverse(),
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.color.withOpacity(0.8),
                  widget.color,
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
