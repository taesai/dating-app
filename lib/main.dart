import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/backend_service.dart';
import 'core/services/sound_service.dart';
import 'core/services/offline_service.dart';
import 'core/config/backend_config.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/theme_provider.dart';
import 'features/pages/dating_home_page.dart';
import 'features/pages/flutter_login_page.dart';
import 'features/pages/migration_page.dart';
import 'features/pages/upgrade_user_page.dart';
import 'features/pages/splash_screen.dart';
import 'core/widgets/rive_loader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  print('🚨🚨🚨 APP DÉMARRE - NOUVEAU BUILD 🚨🚨🚨');
  // Initialiser le backend selon la configuration
  if (BackendConfig.USE_LOCAL_BACKEND) {
    print('🔧 Utilisation du backend local Node.js');
  } else {
    print('☁️ Utilisation d\'Appwrite Cloud');
  }

  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser SharedPreferences AVANT ProviderScope
  print('📦 Initialisation de SharedPreferences...');
  await SharedPreferences.getInstance();
  print('✅ SharedPreferences initialisé');

  // Initialiser les services
  await BackendService().init();
  await SoundService().init();
  OfflineService().init();

  print('✅ Tous les services initialisés');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Attendre que SharedPreferences soit prêt avant de charger le thème
    final prefsAsync = ref.watch(sharedPreferencesProvider);

    return prefsAsync.when(
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: RiveLoader()),
        ),
      ),
      error: (error, stack) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Erreur: $error')),
        ),
      ),
      data: (_) {
        // SharedPreferences est prêt, on peut charger le thème
        final themeState = ref.watch(themeProvider);
        final currentTheme = AppTheme.getTheme(themeState);

        return _buildApp(themeState, currentTheme);
      },
    );
  }

  Widget _buildApp(ThemeState themeState, ThemeData currentTheme) {

    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('fr'), // French
        Locale('es'), // Spanish
      ],

      title: 'Dating App',
      debugShowCheckedModeBanner: false,
      theme: currentTheme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: AppTheme.getTheme(themeState.copyWith(isDark: true, themeMode: ThemeMode.dark)).copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: themeState.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 500),
      themeAnimationCurve: Curves.easeInOut,
      home: const AuthWrapper(),
      routes: {
        '/migration': (context) => const MigrationPage(),
        '/upgrade': (context) => const UpgradeUserPage(),
      },
    );
  }
}

/// Wrapper qui gère l'authentification avec Riverpod
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _showSplash = true;

  void _completeSplash() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onComplete: _completeSplash);
    }

    // Attendre que SharedPreferences soit prêt
    final prefsAsync = ref.watch(sharedPreferencesProvider);

    return prefsAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: RiveLoader(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Erreur d\'initialisation: $error'),
        ),
      ),
      data: (_) {
        // Une fois les prefs chargées, écouter l'état d'authentification
        final authState = ref.watch(authProvider);

        if (authState.isLoading) {
          return const Scaffold(
            body: Center(
              child: RiveLoader(),
            ),
          );
        }

        if (authState.isAuthenticated && authState.currentUser != null) {
          print('✅ Utilisateur connecté: ${authState.currentUser!.email}');
          return const DatingHomePage();
        } else {
          print('⚠️ Pas d\'utilisateur connecté');
          return const FlutterLoginPage();
        }
      },
    );
  }
}