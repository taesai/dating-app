import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../core/services/backend_service.dart';
import '../../core/config/backend_config.dart';
import '../../core/providers/auth_provider.dart';
import 'dating_home_page.dart';

class FlutterLoginPage extends ConsumerStatefulWidget {
  const FlutterLoginPage({super.key});

  @override
  ConsumerState<FlutterLoginPage> createState() => _FlutterLoginPageState();
}

class _FlutterLoginPageState extends ConsumerState<FlutterLoginPage> {
  final _backend = BackendService();
  Duration get loginTime => const Duration(milliseconds: 2250);
  bool _imagesLoaded = false;

  // Carousel d'images de fond
  final List<String> _backgroundImages = [
    'assets/images/background.jpg',
    // 'assets/images/bg2.jpg',
    // 'assets/images/bg3.jpg',
    // 'assets/images/bg4.jpg',
    // 'assets/images/bg5.jpg',
    // 'assets/images/bg6.jpg',
    // 'assets/images/bg7.jpg',
    
  ];

  @override
  void initState() {
    super.initState();
    _preloadImages();
  }

  Future<void> _preloadImages() async {
    try {
      // Précharger toutes les images de fond
      for (final imagePath in _backgroundImages) {
        await precacheImage(AssetImage(imagePath), context);
      }
      // Précharger le logo aussi
      await precacheImage(const AssetImage('assets/logo.png'), context);

      if (mounted) {
        setState(() {
          _imagesLoaded = true;
        });
      }
    } catch (e) {
      print('⚠️ Erreur préchargement images: $e');
      // Continuer quand même
      if (mounted) {
        setState(() {
          _imagesLoaded = true;
        });
      }
    }
  }

  Future<String?> _authUser(LoginData data) async {
    try {
      print('🔐 Tentative de connexion pour: ${data.name}');

      final success = await ref.read(authProvider.notifier).login(
        data.name,
        data.password,
      );

      if (success) {
        print('✅ Connexion réussie !');
        return null; // null = succès
      } else {
        final error = ref.read(authProvider).error ?? 'Erreur de connexion';
        print('❌ Erreur: $error');

        // Afficher aussi un SnackBar pour plus de visibilité
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(error)),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }

        return error;
      }
    } catch (e) {
      print('❌ Exception lors du login: $e');
      final errorMsg = 'Erreur de connexion: ${e.toString()}';

      // Afficher un SnackBar pour l'exception aussi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMsg)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      return errorMsg;
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    try {
      print('📝 Tentative d\'inscription pour: ${data.name}');

      // Vérifier que le nom est fourni
      if (data.additionalSignupData == null ||
          data.additionalSignupData!['name'] == null ||
          data.additionalSignupData!['name'].toString().isEmpty) {
        return 'Veuillez entrer votre nom';
      }

      // Créer le compte
      dynamic user = await _backend.createAccount(
        email: data.name!,
        password: data.password!,
        name: data.additionalSignupData!['name'].toString(),
      );

      // Obtenir la position
      Position? position;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission != LocationPermission.deniedForever) {
          position = await Geolocator.getCurrentPosition();
        }
      } catch (e) {
        // Position par défaut (Paris)
        position = Position(
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      // Créer le profil (seulement pour Appwrite)
      if (!BackendConfig.USE_LOCAL_BACKEND) {
        final userId = user is Map ? user['id'] : user.$id;
        final userEmail = user is Map ? user['email'] : user.email;

        await _backend.createUserProfile(
          userId: userId,
          name: data.additionalSignupData!['name'].toString(),
          email: userEmail,
          age: int.tryParse(data.additionalSignupData!['age']?.toString() ?? '18') ?? 18,
          gender: data.additionalSignupData!['gender']?.toString() ?? 'Autre',
          bio: '',
          latitude: position?.latitude ?? 48.8566,
          longitude: position?.longitude ?? 2.3522,
        );

        // Se connecter
        await _backend.login(
          email: data.name!,
          password: data.password!,
        );
      }

      print('✅ Inscription réussie !');
      return null; // null = succès
    } catch (e) {
      print('❌ Exception lors de l\'inscription: $e');

      // Extraire un message d'erreur plus clair
      String errorMessage = 'Erreur lors de l\'inscription';
      final errorStr = e.toString().toLowerCase();

      // Erreurs de compte existant
      if (errorStr.contains('user already exists') ||
          errorStr.contains('email already') ||
          errorStr.contains('account') && errorStr.contains('exists')) {
        errorMessage = '📧 Un compte existe déjà avec cet email';
      }
      // Erreurs de format
      else if (errorStr.contains('invalid email') ||
               errorStr.contains('email') && errorStr.contains('invalid')) {
        errorMessage = '📧 Format d\'email invalide';
      }
      else if (errorStr.contains('password') && errorStr.contains('short')) {
        errorMessage = '🔒 Le mot de passe doit contenir au moins 8 caractères';
      }
      else if (errorStr.contains('password') && errorStr.contains('weak')) {
        errorMessage = '🔒 Le mot de passe est trop faible';
      }
      // Erreurs réseau
      else if (errorStr.contains('network') ||
               errorStr.contains('timeout') ||
               errorStr.contains('connection') ||
               errorStr.contains('failed to connect') ||
               errorStr.contains('socketexception')) {
        errorMessage = '📡 Erreur réseau. Vérifiez votre connexion Internet';
      }
      else if (errorStr.contains('no internet') ||
               errorStr.contains('offline')) {
        errorMessage = '📡 Pas de connexion Internet';
      }
      // Erreurs serveur
      else if (errorStr.contains('server error') ||
               errorStr.contains('500') ||
               errorStr.contains('503')) {
        errorMessage = '🔧 Erreur serveur. Réessayez plus tard';
      }
      // Erreurs de géolocalisation
      else if (errorStr.contains('location') || errorStr.contains('gps')) {
        errorMessage = '📍 Impossible d\'obtenir votre position (utilisation de Paris par défaut)';
      }
      // Message générique
      else {
        final cleanError = e.toString()
            .replaceAll('Exception: ', '')
            .replaceAll('Error: ', '')
            .split('\n')
            .first
            .trim();

        if (cleanError.length < 100) {
          errorMessage = '❌ $cleanError';
        } else {
          errorMessage = '❌ Une erreur est survenue. Veuillez réessayer';
        }
      }

      // Afficher un SnackBar pour plus de visibilité
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      return errorMessage;
    }
  }

  Future<String?> _recoverPassword(String email) async {
    print('🔑 Récupération du mot de passe pour: $email');
    // TODO: Implémenter la récupération de mot de passe
    return 'La récupération de mot de passe n\'est pas encore implémentée';
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Afficher un splash screen de chargement pendant que les images se chargent
    if (!_imagesLoaded) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE91E63),
                isDark ? const Color(0xFF16213E) : const Color(0xFF9C27B0),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite,
                  size: 80,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'Chargement...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Carousel d'images de fond
        CarouselSlider(
          options: CarouselOptions(
            height: MediaQuery.of(context).size.height,
            viewportFraction: 1.0,
            autoPlay: _backgroundImages.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 1000),
            autoPlayCurve: Curves.easeInOut,
            pauseAutoPlayOnTouch: false,
            enlargeCenterPage: false,
          ),
          items: _backgroundImages.map((imagePath) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        // FlutterLogin par-dessus avec transparence
        FlutterLogin(
      title: 'Dating App',
      logo: const AssetImage('assets/images/logo.jpg'), // Optionnel
      onLogin: _authUser,
      onSignup: _signupUser,
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DatingHomePage(),
          ),
        );
      },
      onRecoverPassword: _recoverPassword,
      messages: LoginMessages(
        userHint: 'Email',
        passwordHint: 'Mot de passe',
        confirmPasswordHint: 'Confirmer',
        loginButton: 'SE CONNECTER',
        signupButton: 'S\'INSCRIRE',
        forgotPasswordButton: 'Mot de passe oublié ?',
        recoverPasswordButton: 'ENVOYER',
        goBackButton: 'RETOUR',
        confirmPasswordError: 'Les mots de passe ne correspondent pas',
        recoverPasswordDescription:
            'Nous vous enverrons un email pour réinitialiser votre mot de passe',
        recoverPasswordSuccess: 'Email envoyé !',
      ),
      theme: LoginTheme(
        primaryColor: isDark ? const Color(0xFFFF4081) : const Color(0xFFE91E63),
        accentColor: isDark ? const Color(0xFFBA68C8) : const Color(0xFF9C27B0),
        errorColor: Colors.red,
        titleStyle: TextStyle(
          color: Colors.white,
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.bold,
          fontSize: 32,
          letterSpacing: 2,
        ),
        bodyStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        textFieldStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        buttonStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
        cardTheme: CardTheme(
          color: isDark
              ? const Color(0xFF1E1E1E).withOpacity(0.9)
              : Colors.white.withOpacity(0.4),
          elevation: 20,
          shadowColor: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.9),
          margin: const EdgeInsets.only(top: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        inputTheme: InputDecorationTheme(
          filled: true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFFFF4081) : const Color(0xFFE91E63),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          labelStyle: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          hintStyle: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        buttonTheme: LoginButtonTheme(
          splashColor: isDark
              ? const Color(0xFFFF4081).withOpacity(0.3)
              : const Color(0xFFE91E63).withOpacity(0.3),
          backgroundColor: isDark ? const Color(0xFFFF4081) : const Color(0xFFE91E63),
          highlightColor: isDark ? const Color(0xFFBA68C8) : const Color(0xFF9C27B0),
          elevation: 8.0,
          highlightElevation: 12.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        pageColorLight: Colors.transparent,
        pageColorDark: Colors.transparent,
      ),
      userValidator: (value) {
        if (value == null || !value.contains('@') || !value.endsWith('.com')) {
          return "L'email doit contenir '@' et se terminer par '.com'";
        }
        return null;
      },
      passwordValidator: (value) {
        if (value == null || value.isEmpty) {
          return 'Le mot de passe ne peut pas être vide';
        }
        if (value.length < 8) {
          return 'Le mot de passe doit contenir au moins 8 caractères';
        }
        return null;
      },
      additionalSignupFields: [
        UserFormField(
          keyName: 'name',
          displayName: 'Nom',
          icon: const Icon(Icons.person),
          userType: LoginUserType.name,
        ),
        UserFormField(
          keyName: 'age',
          displayName: 'Âge',
          icon: const Icon(Icons.cake),
          userType: LoginUserType.phone,
          fieldValidator: (value) {
            final age = int.tryParse(value ?? '');
            if (age == null || age < 18) {
              return 'Vous devez avoir au moins 18 ans';
            }
            return null;
          },
        ),
        const UserFormField(
          keyName: 'gender',
          displayName: 'Genre',
          icon: Icon(Icons.people),
          defaultValue: 'Autre',
        ),
      ],
      hideForgotPasswordButton: false,
      hideProvidersTitle: false,
      loginAfterSignUp: true,
      scrollable: true,
      headerWidget: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFFFF4081),
                    const Color(0xFFBA68C8),
                  ]
                : [
                    const Color(0xFFE91E63),
                    const Color(0xFF9C27B0),
                  ],
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.favorite,
          size: 60,
          color: Colors.white,
        ),
      ),
        ),
      ],
    );
  }
}
