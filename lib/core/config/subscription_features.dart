/// Configuration des fonctionnalités par plan d'abonnement
class SubscriptionFeatures {
  // Plans disponibles
  static const String FREE = 'free';
  static const String SILVER = 'silver';
  static const String GOLD = 'gold';

  // Fonctionnalités FREE (gratuit)
  static const int FREE_LIKES_PER_DAY = 10;
  static const int FREE_SUPER_LIKES_PER_DAY = 1;
  static const bool FREE_SEE_WHO_LIKED_YOU = false;
  static const bool FREE_UNLIMITED_REWINDS = false;
  static const bool FREE_PROFILE_BOOST = false;
  static const bool FREE_READ_RECEIPTS = false;
  static const bool FREE_ADVANCED_FILTERS = false;
  static const int FREE_PHOTO_LIMIT = 6;
  static const bool FREE_HIDE_ADS = false;
  static const bool FREE_INCOGNITO_MODE = false;
  static const bool FREE_PRIORITY_SUPPORT = false;

  // Fonctionnalités SILVER (premium)
  static const int SILVER_LIKES_PER_DAY = 50;
  static const int SILVER_SUPER_LIKES_PER_DAY = 5;
  static const bool SILVER_SEE_WHO_LIKED_YOU = true;
  static const bool SILVER_UNLIMITED_REWINDS = false;
  static const bool SILVER_PROFILE_BOOST = true; // 1 boost/mois
  static const bool SILVER_READ_RECEIPTS = true;
  static const bool SILVER_ADVANCED_FILTERS = true;
  static const int SILVER_PHOTO_LIMIT = 12;
  static const bool SILVER_HIDE_ADS = true;
  static const bool SILVER_INCOGNITO_MODE = false;
  static const bool SILVER_PRIORITY_SUPPORT = false;

  // Fonctionnalités GOLD (premium+)
  static const int GOLD_LIKES_PER_DAY = -1; // illimité
  static const int GOLD_SUPER_LIKES_PER_DAY = 10;
  static const bool GOLD_SEE_WHO_LIKED_YOU = true;
  static const bool GOLD_UNLIMITED_REWINDS = true;
  static const bool GOLD_PROFILE_BOOST = true; // 3 boosts/mois
  static const bool GOLD_READ_RECEIPTS = true;
  static const bool GOLD_ADVANCED_FILTERS = true;
  static const int GOLD_PHOTO_LIMIT = 20;
  static const bool GOLD_HIDE_ADS = true;
  static const bool GOLD_INCOGNITO_MODE = true;
  static const bool GOLD_PRIORITY_SUPPORT = true;

  /// Obtenir les fonctionnalités pour un plan donné
  static Map<String, dynamic> getFeaturesForPlan(String plan) {
    switch (plan.toLowerCase()) {
      case SILVER:
        return {
          'likesPerDay': SILVER_LIKES_PER_DAY,
          'superLikesPerDay': SILVER_SUPER_LIKES_PER_DAY,
          'seeWhoLikedYou': SILVER_SEE_WHO_LIKED_YOU,
          'unlimitedRewinds': SILVER_UNLIMITED_REWINDS,
          'profileBoost': SILVER_PROFILE_BOOST,
          'readReceipts': SILVER_READ_RECEIPTS,
          'advancedFilters': SILVER_ADVANCED_FILTERS,
          'photoLimit': SILVER_PHOTO_LIMIT,
          'hideAds': SILVER_HIDE_ADS,
          'incognitoMode': SILVER_INCOGNITO_MODE,
          'prioritySupport': SILVER_PRIORITY_SUPPORT,
        };
      case GOLD:
        return {
          'likesPerDay': GOLD_LIKES_PER_DAY,
          'superLikesPerDay': GOLD_SUPER_LIKES_PER_DAY,
          'seeWhoLikedYou': GOLD_SEE_WHO_LIKED_YOU,
          'unlimitedRewinds': GOLD_UNLIMITED_REWINDS,
          'profileBoost': GOLD_PROFILE_BOOST,
          'readReceipts': GOLD_READ_RECEIPTS,
          'advancedFilters': GOLD_ADVANCED_FILTERS,
          'photoLimit': GOLD_PHOTO_LIMIT,
          'hideAds': GOLD_HIDE_ADS,
          'incognitoMode': GOLD_INCOGNITO_MODE,
          'prioritySupport': GOLD_PRIORITY_SUPPORT,
        };
      default: // FREE
        return {
          'likesPerDay': FREE_LIKES_PER_DAY,
          'superLikesPerDay': FREE_SUPER_LIKES_PER_DAY,
          'seeWhoLikedYou': FREE_SEE_WHO_LIKED_YOU,
          'unlimitedRewinds': FREE_UNLIMITED_REWINDS,
          'profileBoost': FREE_PROFILE_BOOST,
          'readReceipts': FREE_READ_RECEIPTS,
          'advancedFilters': FREE_ADVANCED_FILTERS,
          'photoLimit': FREE_PHOTO_LIMIT,
          'hideAds': FREE_HIDE_ADS,
          'incognitoMode': FREE_INCOGNITO_MODE,
          'prioritySupport': FREE_PRIORITY_SUPPORT,
        };
    }
  }

  /// Vérifier si une fonctionnalité est disponible pour un plan
  static bool hasFeature(String plan, String feature) {
    final features = getFeaturesForPlan(plan);
    final value = features[feature];
    if (value is bool) return value;
    if (value is int) return value > 0 || value == -1; // -1 = illimité
    return false;
  }

  /// Obtenir le nom d'affichage du plan
  static String getPlanDisplayName(String plan) {
    switch (plan.toLowerCase()) {
      case SILVER:
        return 'Silver 💎';
      case GOLD:
        return 'Gold 🏆';
      default:
        return 'Free';
    }
  }

  /// Obtenir la couleur du plan
  static String getPlanColor(String plan) {
    switch (plan.toLowerCase()) {
      case SILVER:
        return '#C0C0C0'; // Argenté
      case GOLD:
        return '#FFD700'; // Doré
      default:
        return '#808080'; // Gris
    }
  }
}
