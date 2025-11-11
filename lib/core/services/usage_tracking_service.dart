import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dating_user.dart';

class UsageTrackingService {
  static const String _swipesKey = 'daily_swipes';
  static const String _likesKey = 'daily_likes';
  static const String _dateKey = 'tracking_date';

  // Subscription limits
  static const Map<String, int> swipeLimits = {
    'free': 20,
    'silver': 100,
    'gold': -1, // -1 = unlimited
  };

  static const Map<String, int> likeLimits = {
    'free': 10,
    'silver': 50,
    'gold': -1, // -1 = unlimited
  };

  Future<void> _checkAndResetIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final savedDate = prefs.getString(_dateKey);

    if (savedDate != today) {
      // New day - reset counters
      await prefs.setInt(_swipesKey, 0);
      await prefs.setInt(_likesKey, 0);
      await prefs.setString(_dateKey, today);
    }
  }

  Future<int> getSwipesCount() async {
    await _checkAndResetIfNewDay();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_swipesKey) ?? 0;
  }

  Future<int> getLikesCount() async {
    await _checkAndResetIfNewDay();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_likesKey) ?? 0;
  }

  Future<void> incrementSwipes() async {
    await _checkAndResetIfNewDay();
    final prefs = await SharedPreferences.getInstance();
    final current = await getSwipesCount();
    await prefs.setInt(_swipesKey, current + 1);
  }

  Future<void> incrementLikes() async {
    await _checkAndResetIfNewDay();
    final prefs = await SharedPreferences.getInstance();
    final current = await getLikesCount();
    await prefs.setInt(_likesKey, current + 1);
  }

  int getSwipeLimit(String plan) {
    return swipeLimits[plan] ?? swipeLimits['free']!;
  }

  int getLikeLimit(String plan) {
    return likeLimits[plan] ?? likeLimits['free']!;
  }

  Future<bool> canSwipe(String plan) async {
    final limit = getSwipeLimit(plan);
    if (limit == -1) return true; // Unlimited
    final count = await getSwipesCount();
    return count < limit;
  }

  Future<bool> canLike(String plan) async {
    final limit = getLikeLimit(plan);
    if (limit == -1) return true; // Unlimited
    final count = await getLikesCount();
    return count < limit;
  }

  Future<String> getSwipeStatus(String plan) async {
    final limit = getSwipeLimit(plan);
    if (limit == -1) return 'Illimité';
    final count = await getSwipesCount();
    return '$count/$limit swipes aujourd\'hui';
  }

  Future<String> getLikeStatus(String plan) async {
    final limit = getLikeLimit(plan);
    if (limit == -1) return 'Illimité';
    final count = await getLikesCount();
    return '$count/$limit likes aujourd\'hui';
  }
}
