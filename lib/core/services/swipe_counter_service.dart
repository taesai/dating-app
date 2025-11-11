import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer le compteur de swipes quotidiens pour les utilisateurs non approuvés
class SwipeCounterService {
  static const String _keyPrefix = 'swipe_count_';
  static const String _dateKeyPrefix = 'swipe_date_';
  static const int _dailyLimit = 20;

  /// Obtenir la limite quotidienne de swipes pour les utilisateurs non approuvés
  static int get dailyLimit => _dailyLimit;

  /// Obtenir le nombre de swipes restants pour aujourd'hui
  Future<int> getSwipesRemaining(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final lastDate = prefs.getString('$_dateKeyPrefix$userId');

    // Si la date est différente, réinitialiser le compteur
    if (lastDate != today) {
      await _resetCounter(userId);
      return _dailyLimit;
    }

    final count = prefs.getInt('$_keyPrefix$userId') ?? 0;
    return _dailyLimit - count;
  }

  /// Incrémenter le compteur de swipes
  Future<bool> incrementSwipeCount(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final lastDate = prefs.getString('$_dateKeyPrefix$userId');

    // Si la date est différente, réinitialiser le compteur
    if (lastDate != today) {
      await _resetCounter(userId);
    }

    final count = prefs.getInt('$_keyPrefix$userId') ?? 0;

    // Vérifier si la limite est atteinte
    if (count >= _dailyLimit) {
      return false; // Limite atteinte
    }

    // Incrémenter le compteur
    await prefs.setInt('$_keyPrefix$userId', count + 1);
    await prefs.setString('$_dateKeyPrefix$userId', today);

    print('📊 Swipes: ${count + 1}/$_dailyLimit pour l\'utilisateur $userId');

    return true; // Succès
  }

  /// Réinitialiser le compteur pour un utilisateur
  Future<void> _resetCounter(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyPrefix$userId', 0);
    await prefs.setString('$_dateKeyPrefix$userId', _getTodayString());
    print('🔄 Compteur de swipes réinitialisé pour l\'utilisateur $userId');
  }

  /// Obtenir la date d'aujourd'hui au format YYYY-MM-DD
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Vérifier si un utilisateur peut swiper (a des swipes restants)
  Future<bool> canSwipe(String userId) async {
    final remaining = await getSwipesRemaining(userId);
    return remaining > 0;
  }

  /// Obtenir le nombre actuel de swipes effectués aujourd'hui
  Future<int> getSwipeCount(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final lastDate = prefs.getString('$_dateKeyPrefix$userId');

    // Si la date est différente, retourner 0
    if (lastDate != today) {
      return 0;
    }

    return prefs.getInt('$_keyPrefix$userId') ?? 0;
  }
}
