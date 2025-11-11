import 'package:flutter/material.dart';

/// Types de transitions disponibles
enum TransitionType {
  slide,
  fade,
  scale,
  slideUp,
  slideDown,
  scaleRotate,
  morphing,        // Transformation fluide (nouveau)
  slideAndFade,    // Slide avec fade (nouveau)
  parallax,        // Effet de profondeur (nouveau)
  elastic,         // Effet élastique (nouveau)
}

/// Route personnalisée avec animations fluides
class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final TransitionType transitionType;
  final Duration duration;
  final Curve curve;

  CustomPageRoute({
    required this.page,
    this.transitionType = TransitionType.slide,
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeInOut,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(
              transitionType,
              animation,
              secondaryAnimation,
              child,
              curve,
            );
          },
        );

  static Widget _buildTransition(
    TransitionType type,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    Curve curve,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );

    switch (type) {
      case TransitionType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );

      case TransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case TransitionType.scaleRotate:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(curvedAnimation),
          child: RotationTransition(
            turns: Tween<double>(
              begin: 0.05,
              end: 0.0,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );

      case TransitionType.morphing:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.92,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          )),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.08),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
              )),
              child: child,
            ),
          ),
        );

      case TransitionType.slideAndFade:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
            )),
            child: child,
          ),
        );

      case TransitionType.parallax:
        return Stack(
          children: [
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(-0.3, 0.0),
              ).animate(CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInOutCubic,
              )),
              child: FadeTransition(
                opacity: Tween<double>(
                  begin: 1.0,
                  end: 0.5,
                ).animate(secondaryAnimation),
                child: Container(), // Page précédente (si disponible)
              ),
            ),
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            ),
          ],
        );

      case TransitionType.elastic:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.85,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          )),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
            )),
            child: child,
          ),
        );
    }
  }
}

/// Extension pour faciliter la navigation avec animations
extension NavigationExtension on BuildContext {
  /// Navigation avec slide de droite à gauche
  Future<T?> pushWithSlide<T>(Widget page) {
    return Navigator.push<T>(
      this,
      CustomPageRoute(
        page: page,
        transitionType: TransitionType.slide,
      ),
    );
  }

  /// Navigation avec fade
  Future<T?> pushWithFade<T>(Widget page) {
    return Navigator.push<T>(
      this,
      CustomPageRoute(
        page: page,
        transitionType: TransitionType.fade,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Navigation avec scale + fade (pour les profils)
  Future<T?> pushWithScale<T>(Widget page) {
    return Navigator.push<T>(
      this,
      CustomPageRoute(
        page: page,
        transitionType: TransitionType.scale,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
      ),
    );
  }

  /// Navigation modale avec slide du bas
  Future<T?> pushModalWithSlideUp<T>(Widget page) {
    return Navigator.push<T>(
      this,
      CustomPageRoute(
        page: page,
        transitionType: TransitionType.slideUp,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  /// Navigation avec rotation + scale (effet spectaculaire)
  Future<T?> pushWithScaleRotate<T>(Widget page) {
    return Navigator.push<T>(
      this,
      CustomPageRoute(
        page: page,
        transitionType: TransitionType.scaleRotate,
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
      ),
    );
  }

  /// Navigation avec effet morphing (transformation fluide)
  Future<T?> pushWithMorphing<T>(Widget page) {
    return Navigator.push<T>(
      this,
      CustomPageRoute(
        page: page,
        transitionType: TransitionType.morphing,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  /// Navigation avec slide et fade combinés
  Future<T?> pushWithSlideAndFade<T>(Widget page) {
    return Navigator.push<T>(
      this,
      CustomPageRoute(
        page: page,
        transitionType: TransitionType.slideAndFade,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  /// Navigation avec effet parallax (profondeur)
  Future<T?> pushWithParallax<T>(Widget page) {
    return Navigator.push<T>(
      this,
      CustomPageRoute(
        page: page,
        transitionType: TransitionType.parallax,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  /// Navigation avec effet élastique
  Future<T?> pushWithElastic<T>(Widget page) {
    return Navigator.push<T>(
      this,
      CustomPageRoute(
        page: page,
        transitionType: TransitionType.elastic,
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
      ),
    );
  }
}

/// Widget pour des transitions animées lors du changement de contenu
class AnimatedPageSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AnimatedPageSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
