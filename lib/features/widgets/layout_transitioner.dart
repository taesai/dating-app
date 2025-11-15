import 'package:flutter/material.dart';

/// Widget pour gérer les transitions animées entre layouts (mobile/tablet/desktop)
/// tout en préservant l'état des widgets enfants grâce à IndexedStack
class LayoutTransitioner extends StatefulWidget {
  final int layoutType; // 0=desktop, 1=tablet, 2=mobile
  final Widget desktopChild;
  final Widget tabletChild;
  final Widget mobileChild;

  const LayoutTransitioner({
    super.key,
    required this.layoutType,
    required this.desktopChild,
    required this.tabletChild,
    required this.mobileChild,
  });

  @override
  State<LayoutTransitioner> createState() => _LayoutTransitionerState();
}

class _LayoutTransitionerState extends State<LayoutTransitioner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  int _previousLayoutType = 2; // mobile par défaut

  @override
  void initState() {
    super.initState();
    _previousLayoutType = widget.layoutType;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.value = 1.0;
  }

  @override
  void didUpdateWidget(LayoutTransitioner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.layoutType != widget.layoutType) {
      _previousLayoutType = oldWidget.layoutType;
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // IndexedStack pour garder l'état
        IndexedStack(
          index: widget.layoutType,
          children: [
            widget.desktopChild,
            widget.tabletChild,
            widget.mobileChild,
          ],
        ),
        // Overlay d'animation morphable
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _animationController.value == 1.0,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                if (_animationController.value == 1.0) {
                  return const SizedBox.shrink();
                }

                // Animation morphable élégante sans dépendance externe
                final progress = 1 - _animationController.value;
                final borderRadius = 20.0 * progress;

                return FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeAnimation),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.05).animate(_scaleAnimation),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(borderRadius),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.15 * progress),
                            Theme.of(context).colorScheme.secondary.withOpacity(0.08 * progress),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.1 * progress),
                            blurRadius: 30 * progress,
                            spreadRadius: 5 * progress,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
