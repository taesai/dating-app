import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/background_video.dart';
import '../../core/utils/responsive_helper.dart';

/// Page de tutoriel pour les nouveaux utilisateurs
class OnboardingTutorialPage extends StatefulWidget {
  const OnboardingTutorialPage({super.key});

  @override
  State<OnboardingTutorialPage> createState() => _OnboardingTutorialPageState();
}

class _OnboardingTutorialPageState extends State<OnboardingTutorialPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<TutorialStep> _steps = [
    TutorialStep(
      icon: Icons.favorite,
      title: 'Bienvenue sur Dating App ! 💕',
      description:
          'Découvrez des profils intéressants à travers des vidéos courtes. '
          'Swipez pour trouver votre match parfait !',
      color: Colors.pink,
      videoAsset: 'assets/videos/bg1.mp4',
    ),
    TutorialStep(
      icon: Icons.swipe,
      title: 'Comment swiper ?',
      description:
          '• Swipez à DROITE ❤️ pour liker\n'
          '• Swipez à GAUCHE ❌ pour passer\n'
          '• Swipez vers le HAUT 👤 pour voir le profil complet\n'
          '• Tapez sur l\'écran ⭐ pour super liker',
      color: Colors.purple,
      videoAsset: 'assets/videos/bg2.mp4',
    ),
    TutorialStep(
      icon: Icons.celebration,
      title: 'C\'est un Match ! 🎉',
      description:
          'Lorsque deux personnes se likent mutuellement, c\'est un match !\n\n'
          'Vous pourrez alors commencer à discuter dans la section Messages.',
      color: Colors.orange,
      videoAsset: 'assets/videos/bg3.mp4',
    ),
    TutorialStep(
      icon: Icons.chat_bubble_outline,
      title: 'Chat & Messages',
      description:
          'Discutez avec vos matchs, envoyez des emojis 😊\n\n'
          'Les membres Premium peuvent également envoyer des photos !',
      color: Colors.blue,
      videoAsset: 'assets/videos/bg1.mp4',
    ),
    TutorialStep(
      icon: Icons.workspace_premium,
      title: 'Fonctionnalités Premium',
      description:
          '🌟 Super Likes illimités\n'
          '💌 Voir qui vous a liké\n'
          '📸 Envoyer des photos dans le chat\n'
          '🔍 Filtres de recherche avancés\n'
          '⚡ Et bien plus encore !',
      color: Colors.amber,
      videoAsset: 'assets/videos/bg2.mp4',
    ),
    TutorialStep(
      icon: Icons.security,
      title: 'Conseils de sécurité',
      description:
          '• Ne partagez jamais vos informations personnelles trop tôt\n'
          '• Rencontrez dans des lieux publics\n'
          '• Signalez tout comportement inapproprié\n'
          '• Faites confiance à votre instinct',
      color: Colors.green,
      videoAsset: 'assets/videos/bg3.mp4',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _completeTutorial();
    }
  }

  Future<void> _skipTutorial() async {
    await _completeTutorial();
  }

  Future<void> _completeTutorial() async {
    // Marquer le tutoriel comme complété dans SharedPreferences (persistant)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
    print('✅ Tutoriel marqué comme complété');

    // Fermer la page de tutoriel
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isMobile = !isDesktop && !isTablet;

    // Tailles responsives
    final skipButtonSize = isDesktop ? 18.0 : (isTablet ? 17.0 : 16.0);
    final iconSize = isDesktop ? 180.0 : (isTablet ? 150.0 : 140.0);
    final titleSize = isDesktop ? 36.0 : (isTablet ? 32.0 : 28.0);
    final descriptionSize = isDesktop ? 18.0 : (isTablet ? 17.0 : 16.0);
    final buttonHeight = isDesktop ? 64.0 : (isTablet ? 60.0 : 56.0);
    final buttonFontSize = isDesktop ? 20.0 : (isTablet ? 19.0 : 18.0);
    final horizontalPadding = isDesktop ? 48.0 : (isTablet ? 36.0 : 24.0);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Bouton Skip avec style neumorphic
            Padding(
              padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: _skipTutorial,
                    child: Text(
                      'Passer',
                      style: TextStyle(
                        fontSize: skipButtonSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Pages du tutoriel
            Expanded(
              child: isDesktop
                  ? Row(
                      children: [
                        // Navigation gauche sur desktop
                        if (_currentPage > 0)
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 40),
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          )
                        else
                          const SizedBox(width: 56),
                        // Contenu
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _steps.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return _buildTutorialPage(_steps[index], iconSize, titleSize, descriptionSize, horizontalPadding);
                            },
                          ),
                        ),
                        // Navigation droite sur desktop
                        if (_currentPage < _steps.length - 1)
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 40),
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          )
                        else
                          const SizedBox(width: 56),
                      ],
                    )
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: _steps.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return _buildTutorialPage(_steps[index], iconSize, titleSize, descriptionSize, horizontalPadding);
                      },
                    ),
            ),

            // Indicateurs de page avec effet glassmorphism
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : (isTablet ? 22 : 20),
                vertical: isDesktop ? 14 : (isTablet ? 13 : 12),
              ),
              margin: EdgeInsets.symmetric(vertical: isDesktop ? 32 : (isTablet ? 28 : 24)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: isDesktop ? 6 : (isTablet ? 5 : 4)),
                    width: _currentPage == index ? (isDesktop ? 40 : (isTablet ? 36 : 32)) : (isDesktop ? 10 : (isTablet ? 9 : 8)),
                    height: isDesktop ? 10 : (isTablet ? 9 : 8),
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? _steps[index].color
                          : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: _currentPage == index
                          ? [
                              BoxShadow(
                                color: _steps[index].color.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            // Bouton Continuer/Commencer avec style neumorphic
            Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Container(
                width: isDesktop ? 400 : double.infinity,
                height: buttonHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _steps[_currentPage].color,
                      _steps[_currentPage].color.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _steps[_currentPage].color.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    _currentPage == _steps.length - 1
                        ? 'Commencer !'
                        : 'Continuer',
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialPage(TutorialStep step, double iconSize, double titleSize, double descriptionSize, double horizontalPadding) {
    return BackgroundVideo(
      videoAsset: step.videoAsset,
      opacity: 0.4,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône animée avec effet glassmorphism
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: step.color.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(-5, -5),
                        ),
                      ],
                    ),
                    child: Icon(
                      step.icon,
                      size: iconSize * 0.57, // Proportionnel à la taille du container
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 48),

            // Titre avec effet glassmorphism
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding * 1.3,
                vertical: titleSize * 0.5,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Text(
                step.title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: titleSize * 0.85),

            // Description avec effet glassmorphism
            Container(
              padding: EdgeInsets.all(descriptionSize * 1.75),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Text(
                step.description,
                style: TextStyle(
                  fontSize: descriptionSize,
                  height: 1.6,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  shadows: const [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modèle pour chaque étape du tutoriel
class TutorialStep {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String videoAsset;

  TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.videoAsset,
  });
}

/// Vérifier si le tutoriel a été complété
class TutorialHelper {
  static Future<bool> hasCompletedTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tutorial_completed') ?? false;
  }

  static Future<void> markTutorialAsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
  }

  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tutorial_completed');
  }
}
