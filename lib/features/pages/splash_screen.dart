import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'dart:async';
import '../../core/widgets/rive_loader.dart';

/// Splash screen avec animation Rive
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Configuration de l'animation de fade
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    // Lancer l'animation
    _controller.forward();

    // Timer pour passer à la page suivante
    Timer(const Duration(milliseconds: 3000), () {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
              Colors.purple.shade700,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animation Rive du coeur
                SizedBox(
                  width: 250,
                  height: 250,
                  child: RiveAnimation.asset(
                    'assets/animations/16305-30720-heart.riv',
                    fit: BoxFit.contain,
                    onInit: (artboard) {
                      print('✅ Animation Rive chargée avec succès');
                    },
                  ),
                ),
                const SizedBox(height: 32),
                // Nom de l'app
                Text(
                  'Dating App',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Tagline
                Text(
                  'Trouve ton âme soeur',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.95),
                    letterSpacing: 1,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 48),
                // Indicateur de chargement
                const RiveLoader(
                  size: 60,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
