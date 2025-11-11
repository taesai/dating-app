import 'dart:html' as html;
import 'dart:convert';
import 'dart:async';
import '../models/dating_user.dart';
import '../models/chat_message_model.dart';
import '../models/match_model.dart';

/// Service pour gérer le mode hors ligne
class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  // Clés de stockage
  static const String _profilesCacheKey = 'offline_profiles_cache';
  static const String _matchesCacheKey = 'offline_matches_cache';
  static const String _messagesCacheKey = 'offline_messages_cache';
  static const String _pendingActionsCacheKey = 'offline_pending_actions';
  static const String _lastSyncKey = 'offline_last_sync';

  // État de connexion
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionController.stream;
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _syncTimer;

  /// Initialiser le service
  void init() {
    _checkConnection();

    // Écouter les changements de connexion
    html.window.addEventListener('online', (_) => _setOnlineStatus(true));
    html.window.addEventListener('offline', (_) => _setOnlineStatus(false));

    // Sync périodique toutes les 5 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isOnline) {
        syncPendingActions();
      }
    });
  }

  void dispose() {
    _syncTimer?.cancel();
    _connectionController.close();
  }

  void _checkConnection() {
    _isOnline = html.window.navigator.onLine ?? true;
    _connectionController.add(_isOnline);
  }

  void _setOnlineStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectionController.add(_isOnline);

      print(isOnline ? '🌐 Mode en ligne' : '📴 Mode hors ligne');

      if (isOnline) {
        // Sync dès la reconnexion
        syncPendingActions();
      }
    }
  }

  // === CACHE DES PROFILS ===

  /// Sauvegarder les profils dans le cache
  Future<void> cacheProfiles(List<DatingUser> profiles) async {
    try {
      final data = profiles.map((p) => p.toJson()).toList();
      html.window.localStorage[_profilesCacheKey] = jsonEncode(data);
      print('✅ ${profiles.length} profils mis en cache');
    } catch (e) {
      print('❌ Erreur cache profils: $e');
    }
  }

  /// Récupérer les profils du cache
  List<DatingUser>? getCachedProfiles() {
    try {
      final stored = html.window.localStorage[_profilesCacheKey];
      if (stored != null) {
        final List<dynamic> data = jsonDecode(stored);
        return data.map((json) => DatingUser.fromJson(json)).toList();
      }
    } catch (e) {
      print('❌ Erreur lecture cache profils: $e');
    }
    return null;
  }

  // === CACHE DES MATCHS ===

  /// Sauvegarder les matchs dans le cache
  Future<void> cacheMatches(List<MatchModel> matches) async {
    try {
      final data = matches.map((m) => m.toJson()).toList();
      html.window.localStorage[_matchesCacheKey] = jsonEncode(data);
      print('✅ ${matches.length} matchs mis en cache');
    } catch (e) {
      print('❌ Erreur cache matchs: $e');
    }
  }

  /// Récupérer les matchs du cache
  List<MatchModel>? getCachedMatches() {
    try {
      final stored = html.window.localStorage[_matchesCacheKey];
      if (stored != null) {
        final List<dynamic> data = jsonDecode(stored);
        return data.map((json) => MatchModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('❌ Erreur lecture cache matchs: $e');
    }
    return null;
  }

  // === CACHE DES MESSAGES ===

  /// Sauvegarder les messages dans le cache
  Future<void> cacheMessages(String matchId, List<ChatMessageModel> messages) async {
    try {
      final allMessages = getAllCachedMessages();
      allMessages[matchId] = messages.map((m) => m.toJson()).toList();
      html.window.localStorage[_messagesCacheKey] = jsonEncode(allMessages);
      print('✅ ${messages.length} messages mis en cache pour match $matchId');
    } catch (e) {
      print('❌ Erreur cache messages: $e');
    }
  }

  /// Récupérer les messages du cache pour un match
  List<ChatMessageModel>? getCachedMessages(String matchId) {
    try {
      final allMessages = getAllCachedMessages();
      if (allMessages.containsKey(matchId)) {
        final List<dynamic> data = allMessages[matchId];
        return data.map((json) => ChatMessageModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('❌ Erreur lecture cache messages: $e');
    }
    return null;
  }

  /// Récupérer tous les messages en cache
  Map<String, dynamic> getAllCachedMessages() {
    try {
      final stored = html.window.localStorage[_messagesCacheKey];
      if (stored != null) {
        return Map<String, dynamic>.from(jsonDecode(stored));
      }
    } catch (e) {
      print('❌ Erreur lecture cache messages: $e');
    }
    return {};
  }

  // === ACTIONS PENDANTES (pour sync) ===

  /// Ajouter une action à synchroniser plus tard
  Future<void> addPendingAction(Map<String, dynamic> action) async {
    try {
      final actions = getPendingActions();
      actions.add(action);
      html.window.localStorage[_pendingActionsCacheKey] = jsonEncode(actions);
      print('📝 Action en attente: ${action['type']}');
    } catch (e) {
      print('❌ Erreur ajout action pendante: $e');
    }
  }

  /// Récupérer toutes les actions pendantes
  List<Map<String, dynamic>> getPendingActions() {
    try {
      final stored = html.window.localStorage[_pendingActionsCacheKey];
      if (stored != null) {
        final List<dynamic> data = jsonDecode(stored);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('❌ Erreur lecture actions pendantes: $e');
    }
    return [];
  }

  /// Synchroniser toutes les actions pendantes
  Future<void> syncPendingActions() async {
    if (!_isOnline) return;

    final actions = getPendingActions();
    if (actions.isEmpty) return;

    print('🔄 Synchronisation de ${actions.length} actions...');

    final failedActions = <Map<String, dynamic>>[];

    for (final action in actions) {
      try {
        // Ici, vous devriez appeler votre backend pour chaque action
        // Par exemple:
        // - sendMessage
        // - likeUser
        // - updateProfile
        // etc.

        await _executeAction(action);
        print('✅ Action synchronisée: ${action['type']}');
      } catch (e) {
        print('❌ Erreur sync action ${action['type']}: $e');
        failedActions.add(action);
      }
    }

    // Garder seulement les actions qui ont échoué
    if (failedActions.isEmpty) {
      html.window.localStorage.remove(_pendingActionsCacheKey);
      print('✅ Toutes les actions ont été synchronisées');
    } else {
      html.window.localStorage[_pendingActionsCacheKey] = jsonEncode(failedActions);
      print('⚠️ ${failedActions.length} actions n\'ont pas pu être synchronisées');
    }

    _updateLastSync();
  }

  /// Exécuter une action
  Future<void> _executeAction(Map<String, dynamic> action) async {
    final type = action['type'];

    switch (type) {
      case 'sendMessage':
        // await BackendService().sendMessage(
        //   matchId: action['matchId'],
        //   receiverId: action['receiverId'],
        //   message: action['message'],
        // );
        print('📤 Message envoyé: ${action['message']}');
        break;

      case 'likeUser':
        // await BackendService().likeUser(
        //   fromUserId: action['fromUserId'],
        //   toUserId: action['toUserId'],
        // );
        print('❤️ Like envoyé à ${action['toUserId']}');
        break;

      case 'updateProfile':
        // await BackendService().updateUserProfile(
        //   userId: action['userId'],
        //   data: action['data'],
        // );
        print('👤 Profil mis à jour');
        break;

      default:
        print('⚠️ Type d\'action inconnu: $type');
    }
  }

  /// Mettre à jour la date de dernière sync
  void _updateLastSync() {
    html.window.localStorage[_lastSyncKey] = DateTime.now().toIso8601String();
  }

  /// Obtenir la date de dernière sync
  DateTime? getLastSyncDate() {
    try {
      final stored = html.window.localStorage[_lastSyncKey];
      if (stored != null) {
        return DateTime.parse(stored);
      }
    } catch (e) {
      print('❌ Erreur lecture dernière sync: $e');
    }
    return null;
  }

  // === GESTION DU CACHE ===

  /// Vider tout le cache
  void clearCache() {
    html.window.localStorage.remove(_profilesCacheKey);
    html.window.localStorage.remove(_matchesCacheKey);
    html.window.localStorage.remove(_messagesCacheKey);
    html.window.localStorage.remove(_pendingActionsCacheKey);
    html.window.localStorage.remove(_lastSyncKey);
    print('🗑️ Cache vidé');
  }

  /// Obtenir la taille du cache en Ko
  int getCacheSize() {
    try {
      int totalSize = 0;

      final keys = [
        _profilesCacheKey,
        _matchesCacheKey,
        _messagesCacheKey,
        _pendingActionsCacheKey,
      ];

      for (final key in keys) {
        final value = html.window.localStorage[key];
        if (value != null) {
          totalSize += value.length;
        }
      }

      return (totalSize / 1024).round(); // Convertir en Ko
    } catch (e) {
      return 0;
    }
  }

  /// Vérifier si les données sont fraîches (moins de X heures)
  bool isCacheFresh({int maxHours = 24}) {
    final lastSync = getLastSyncDate();
    if (lastSync == null) return false;

    final difference = DateTime.now().difference(lastSync);
    return difference.inHours < maxHours;
  }
}
