import 'dart:async';
import '../models/dating_user.dart';
import '../models/match_model.dart';

/// Service de cache global pour éviter les requêtes redondantes
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Cache des profils utilisateurs (userId -> DatingUser)
  final Map<String, DatingUser> _userProfiles = {};
  final Map<String, DateTime> _userProfilesTimestamp = {};

  // Cache des matches (userId -> List<MatchModel>)
  final Map<String, List<MatchModel>> _userMatches = {};
  final Map<String, DateTime> _userMatchesTimestamp = {};

  // Cache des likes reçus/envoyés (userId -> data)
  final Map<String, dynamic> _userLikes = {};
  final Map<String, DateTime> _userLikesTimestamp = {};

  // Cache des compteurs
  final Map<String, Map<String, int>> _counters = {};
  final Map<String, DateTime> _countersTimestamp = {};

  // Durée de validité du cache (5 minutes par défaut)
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Vérifie si le cache est valide
  bool _isCacheValid(DateTime? timestamp) {
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  // ===== PROFILS UTILISATEURS =====

  /// Récupère un profil depuis le cache
  DatingUser? getUserProfile(String userId) {
    if (_isCacheValid(_userProfilesTimestamp[userId])) {
      print('✅ Cache HIT: Profil $userId');
      return _userProfiles[userId];
    }
    print('❌ Cache MISS: Profil $userId');
    return null;
  }

  /// Stocke un profil dans le cache
  void cacheUserProfile(String userId, DatingUser user) {
    _userProfiles[userId] = user;
    _userProfilesTimestamp[userId] = DateTime.now();
    print('💾 Cache SAVE: Profil $userId');
  }

  /// Stocke plusieurs profils en une fois
  void cacheUserProfiles(Map<String, DatingUser> users) {
    final now = DateTime.now();
    users.forEach((userId, user) {
      _userProfiles[userId] = user;
      _userProfilesTimestamp[userId] = now;
    });
    print('💾 Cache SAVE: ${users.length} profils');
  }

  // ===== MATCHES =====

  /// Récupère les matches depuis le cache
  List<MatchModel>? getUserMatches(String userId) {
    if (_isCacheValid(_userMatchesTimestamp[userId])) {
      print('✅ Cache HIT: Matches pour $userId (${_userMatches[userId]?.length ?? 0})');
      return _userMatches[userId];
    }
    print('❌ Cache MISS: Matches pour $userId');
    return null;
  }

  /// Stocke les matches dans le cache
  void cacheUserMatches(String userId, List<MatchModel> matches) {
    _userMatches[userId] = matches;
    _userMatchesTimestamp[userId] = DateTime.now();
    print('💾 Cache SAVE: ${matches.length} matches pour $userId');
  }

  // ===== LIKES =====

  /// Récupère les likes depuis le cache
  dynamic getUserLikes(String userId) {
    if (_isCacheValid(_userLikesTimestamp[userId])) {
      print('✅ Cache HIT: Likes pour $userId');
      return _userLikes[userId];
    }
    print('❌ Cache MISS: Likes pour $userId');
    return null;
  }

  /// Stocke les likes dans le cache
  void cacheUserLikes(String userId, dynamic likes) {
    _userLikes[userId] = likes;
    _userLikesTimestamp[userId] = DateTime.now();
    print('💾 Cache SAVE: Likes pour $userId');
  }

  // ===== COMPTEURS =====

  /// Récupère les compteurs depuis le cache
  Map<String, int>? getCounters(String userId) {
    if (_isCacheValid(_countersTimestamp[userId])) {
      print('✅ Cache HIT: Compteurs pour $userId');
      return _counters[userId];
    }
    print('❌ Cache MISS: Compteurs pour $userId');
    return null;
  }

  /// Stocke les compteurs dans le cache
  void cacheCounters(String userId, Map<String, int> counters) {
    _counters[userId] = counters;
    _countersTimestamp[userId] = DateTime.now();
    print('💾 Cache SAVE: Compteurs pour $userId');
  }

  // ===== INVALIDATION =====

  /// Invalide le cache d'un utilisateur spécifique
  void invalidateUser(String userId) {
    _userProfiles.remove(userId);
    _userProfilesTimestamp.remove(userId);
    print('🗑️ Cache INVALIDATE: Profil $userId');
  }

  /// Invalide les matches d'un utilisateur
  void invalidateMatches(String userId) {
    _userMatches.remove(userId);
    _userMatchesTimestamp.remove(userId);
    print('🗑️ Cache INVALIDATE: Matches $userId');
  }

  /// Invalide les likes d'un utilisateur
  void invalidateLikes(String userId) {
    _userLikes.remove(userId);
    _userLikesTimestamp.remove(userId);
    print('🗑️ Cache INVALIDATE: Likes $userId');
  }

  /// Invalide les compteurs d'un utilisateur
  void invalidateCounters(String userId) {
    _counters.remove(userId);
    _countersTimestamp.remove(userId);
    print('🗑️ Cache INVALIDATE: Compteurs $userId');
  }

  /// Vide tout le cache
  void clearAll() {
    _userProfiles.clear();
    _userProfilesTimestamp.clear();
    _userMatches.clear();
    _userMatchesTimestamp.clear();
    _userLikes.clear();
    _userLikesTimestamp.clear();
    _counters.clear();
    _countersTimestamp.clear();
    print('🗑️ Cache CLEAR ALL');
  }

  /// Nettoie les entrées expirées (appeler périodiquement)
  void cleanExpired() {
    final now = DateTime.now();

    // Nettoyer les profils expirés
    _userProfilesTimestamp.removeWhere((key, timestamp) {
      if (now.difference(timestamp) >= _cacheDuration) {
        _userProfiles.remove(key);
        return true;
      }
      return false;
    });

    // Nettoyer les matches expirés
    _userMatchesTimestamp.removeWhere((key, timestamp) {
      if (now.difference(timestamp) >= _cacheDuration) {
        _userMatches.remove(key);
        return true;
      }
      return false;
    });

    // Nettoyer les likes expirés
    _userLikesTimestamp.removeWhere((key, timestamp) {
      if (now.difference(timestamp) >= _cacheDuration) {
        _userLikes.remove(key);
        return true;
      }
      return false;
    });

    // Nettoyer les compteurs expirés
    _countersTimestamp.removeWhere((key, timestamp) {
      if (now.difference(timestamp) >= _cacheDuration) {
        _counters.remove(key);
        return true;
      }
      return false;
    });

    print('🧹 Cache nettoyé');
  }
}
