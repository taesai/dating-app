import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/backend_service.dart';
import '../models/dating_user.dart';

/// État d'authentification
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final DatingUser? currentUser;
  final String? error;

  const AuthState({
    this.isLoading = true,
    this.isAuthenticated = false,
    this.currentUser,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    DatingUser? currentUser,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentUser: currentUser ?? this.currentUser,
      error: error,
    );
  }
}

/// Notifier pour gérer l'état d'authentification
class AuthNotifier extends StateNotifier<AuthState> {
  final BackendService _backend;
  final SharedPreferences _prefs;

  AuthNotifier(this._backend, this._prefs) : super(const AuthState()) {
    _checkAuthStatus();
  }

  static const String _authKey = 'is_authenticated';
  static const String _userIdKey = 'user_id';

  /// Vérifie si l'utilisateur est déjà connecté au démarrage
  Future<void> _checkAuthStatus() async {
    try {
      state = state.copyWith(isLoading: true);

      // Vérifier si l'utilisateur était connecté
      final wasAuthenticated = _prefs.getBool(_authKey) ?? false;

      if (wasAuthenticated) {
        try {
          // Essayer de récupérer l'utilisateur actuel depuis Appwrite
          final currentUserDoc = await _backend.getCurrentUser();
          final profileData = (currentUserDoc is Map)
              ? currentUserDoc
              : (currentUserDoc.data is Map ? currentUserDoc.data : {});

          final user = DatingUser.fromJson(profileData);

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            currentUser: user,
          );
          print('✅ Session restaurée pour: ${user.name}');
        } catch (e) {
          print('⚠️ Session invalide ou expirée, nettoyage en cours...');
          // Session invalide/expirée - nettoyer silencieusement
          await _prefs.remove(_authKey);
          await _prefs.remove(_userIdKey);

          // Essayer de nettoyer la session côté serveur
          try {
            await _backend.logout();
          } catch (_) {}

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: false,
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
        );
      }
    } catch (e) {
      print('❌ Erreur vérification auth: $e');
      // Si erreur, déconnecter proprement
      await logout();
    }
  }

  /// Connexion utilisateur
  Future<bool> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      print('🔐 Tentative de connexion pour: $email');

      // Nettoyer les données du précédent utilisateur
      final oldUserId = _prefs.getString(_userIdKey);
      if (oldUserId != null) {
        await _prefs.remove('swipe_count_$oldUserId');
        await _prefs.remove('swipe_date_$oldUserId');
        print('🧹 Données de swipes nettoyées pour l\'ancien utilisateur');
      }

      // Vérifier et nettoyer toute session existante
      try {
        await _backend.logout();
        print('🧹 Session précédente nettoyée');
      } catch (e) {
        print('ℹ️ Pas de session à nettoyer ou erreur: $e');
      }

      // Connexion via backend
      await _backend.login(email: email, password: password);

      print('✅ Connexion backend réussie');

      // Récupérer le profil utilisateur
      final currentUserDoc = await _backend.getCurrentUser();
      final profileData = (currentUserDoc is Map)
          ? currentUserDoc
          : (currentUserDoc.data is Map ? currentUserDoc.data : {});

      print('✅ Profil utilisateur récupéré');

      final user = DatingUser.fromJson(profileData);

      // Sauvegarder l'état d'authentification
      await _prefs.setBool(_authKey, true);
      await _prefs.setString(_userIdKey, user.id);

      print('✅ État d\'authentification sauvegardé pour: ${user.name}');

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        currentUser: user,
      );

      return true;
    } catch (e) {
      print('❌ Erreur lors du login: $e');

      // Extraire un message d'erreur plus clair
      String errorMessage = 'Erreur de connexion';
      final errorStr = e.toString().toLowerCase();

      // Erreurs d'authentification
      if (errorStr.contains('invalid credentials') ||
          errorStr.contains('invalid email or password') ||
          errorStr.contains('invalid') && errorStr.contains('password')) {
        errorMessage = '❌ Email ou mot de passe incorrect';
      }
      else if (errorStr.contains('user (role: guests) missing scope') ||
               errorStr.contains('unauthorized')) {
        errorMessage = '❌ Email ou mot de passe incorrect';
      }
      else if (errorStr.contains('user not found') ||
               errorStr.contains('account') && errorStr.contains('not found')) {
        errorMessage = '📧 Aucun compte trouvé avec cet email';
      }
      // Erreurs de format
      else if (errorStr.contains('invalid email') ||
               errorStr.contains('email') && errorStr.contains('invalid')) {
        errorMessage = '📧 Format d\'email invalide';
      }
      else if (errorStr.contains('password') && errorStr.contains('short')) {
        errorMessage = '🔒 Le mot de passe est trop court (min. 8 caractères)';
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
      // Erreurs de limite
      else if (errorStr.contains('too many requests') ||
               errorStr.contains('rate limit')) {
        errorMessage = '⏱️ Trop de tentatives. Réessayez dans quelques minutes';
      }
      // Erreurs serveur
      else if (errorStr.contains('server error') ||
               errorStr.contains('500') ||
               errorStr.contains('503')) {
        errorMessage = '🔧 Erreur serveur. Réessayez plus tard';
      }
      else if (errorStr.contains('service unavailable')) {
        errorMessage = '🔧 Service temporairement indisponible';
      }
      // Message générique avec détails
      else {
        // Nettoyer le message d'erreur
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

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  /// Inscription utilisateur
  Future<bool> register(String email, String password, String name) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Inscription via backend (utilise createAccount)
      await _backend.createAccount(email: email, password: password, name: name);

      // Connexion automatique après inscription
      await _backend.login(email: email, password: password);

      // Récupérer le profil
      final currentUserDoc = await _backend.getCurrentUser();
      final profileData = (currentUserDoc is Map)
          ? currentUserDoc
          : (currentUserDoc.data is Map ? currentUserDoc.data : {});

      final user = DatingUser.fromJson(profileData);

      // Sauvegarder l'état d'authentification
      await _prefs.setBool(_authKey, true);
      await _prefs.setString(_userIdKey, user.id);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        currentUser: user,
      );

      return true;
    } catch (e) {
      print('❌ Erreur lors de l\'inscription: $e');

      // Extraire un message d'erreur plus clair (même logique que login)
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
      // Message générique avec détails
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

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      // Récupérer l'userId avant de nettoyer
      final userId = _prefs.getString(_userIdKey);

      await _backend.logout();
      await _prefs.remove(_authKey);
      await _prefs.remove(_userIdKey);

      // Nettoyer les données de swipes de cet utilisateur
      if (userId != null) {
        await _prefs.remove('swipe_count_$userId');
        await _prefs.remove('swipe_date_$userId');
        print('🧹 Données de swipes nettoyées pour l\'utilisateur $userId');
      }

      state = const AuthState(
        isLoading: false,
        isAuthenticated: false,
      );
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
      // Même en cas d'erreur, nettoyer l'état local
      final userId = _prefs.getString(_userIdKey);

      await _prefs.remove(_authKey);
      await _prefs.remove(_userIdKey);

      // Nettoyer les données de swipes même en cas d'erreur
      if (userId != null) {
        await _prefs.remove('swipe_count_$userId');
        await _prefs.remove('swipe_date_$userId');
      }

      state = const AuthState(
        isLoading: false,
        isAuthenticated: false,
      );
    }
  }

  /// Rafraîchir les données utilisateur
  Future<void> refreshUser() async {
    try {
      final currentUserDoc = await _backend.getCurrentUser();
      final profileData = (currentUserDoc is Map)
          ? currentUserDoc
          : (currentUserDoc.data is Map ? currentUserDoc.data : {});

      final user = DatingUser.fromJson(profileData);

      state = state.copyWith(currentUser: user);
    } catch (e) {
      print('❌ Erreur refresh user: $e');
    }
  }
}

/// Provider pour SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Provider pour le BackendService
final backendServiceProvider = Provider<BackendService>((ref) {
  return BackendService();
});

/// Provider principal pour l'authentification
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).when(
    data: (prefs) => prefs,
    loading: () => throw Exception('SharedPreferences not ready'),
    error: (error, stack) => throw error,
  );

  final backend = ref.watch(backendServiceProvider);

  return AuthNotifier(backend, prefs);
});

/// Provider helper pour accéder facilement à l'utilisateur courant
final currentUserProvider = Provider<DatingUser?>((ref) {
  return ref.watch(authProvider).currentUser;
});

/// Provider helper pour vérifier si l'utilisateur est authentifié
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
