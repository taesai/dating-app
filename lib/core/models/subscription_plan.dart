/// Modèle pour les plans de souscription
class SubscriptionPlan {
  static const String free = 'free';
  static const String silver = 'silver';
  static const String gold = 'gold';

  /// Plan actuel de l'utilisateur
  final String plan;

  /// Date d'expiration du plan (null pour free)
  final DateTime? expiresAt;

  /// Date de début de la souscription
  final DateTime? startedAt;

  SubscriptionPlan({
    required this.plan,
    this.expiresAt,
    this.startedAt,
  });

  /// Vérifier si le plan est actif
  bool get isActive {
    if (plan == free) return true;
    if (expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Obtenir le plan effectif (revenir à FREE si expiré)
  String get effectivePlan {
    if (!isActive) return free;
    return plan;
  }

  /// Limitations du plan
  PlanLimits get limits => PlanLimits.forPlan(effectivePlan);

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      plan: json['plan'] ?? free,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': plan,
      'expiresAt': expiresAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
    };
  }

  SubscriptionPlan copyWith({
    String? plan,
    DateTime? expiresAt,
    DateTime? startedAt,
  }) {
    return SubscriptionPlan(
      plan: plan ?? this.plan,
      expiresAt: expiresAt ?? this.expiresAt,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}

/// Limitations par plan
class PlanLimits {
  final String planName;

  // Limitations de swipes
  final int? maxSwipesPerDay;

  // Limitations de likes
  final int? maxLikesPerDay;

  // Limitations de super likes
  final int maxSuperLikesPerDay;

  // Limitations vidéo
  final int maxVideoDurationSeconds;
  final int maxVideos;

  // Fonctionnalités
  final bool canSeeWhoLikedYou;
  final bool hasAdvancedFilters;
  final bool hasNoAds;
  final int boostsPerMonth;

  const PlanLimits({
    required this.planName,
    this.maxSwipesPerDay,
    this.maxLikesPerDay,
    required this.maxSuperLikesPerDay,
    required this.maxVideoDurationSeconds,
    required this.maxVideos,
    required this.canSeeWhoLikedYou,
    required this.hasAdvancedFilters,
    required this.hasNoAds,
    required this.boostsPerMonth,
  });

  /// Limitations FREE
  static const PlanLimits freePlan = PlanLimits(
    planName: 'FREE',
    maxSwipesPerDay: 20,
    maxLikesPerDay: 10,
    maxSuperLikesPerDay: 0,
    maxVideoDurationSeconds: 3,
    maxVideos: 1,
    canSeeWhoLikedYou: false,
    hasAdvancedFilters: false,
    hasNoAds: false,
    boostsPerMonth: 0,
  );

  /// Limitations SILVER
  static const PlanLimits silverPlan = PlanLimits(
    planName: 'SILVER',
    maxSwipesPerDay: 100,
    maxLikesPerDay: 50,
    maxSuperLikesPerDay: 3,
    maxVideoDurationSeconds: 10,
    maxVideos: 3,
    canSeeWhoLikedYou: true,
    hasAdvancedFilters: true,
    hasNoAds: false,
    boostsPerMonth: 1,
  );

  /// Limitations GOLD
  static const PlanLimits goldPlan = PlanLimits(
    planName: 'GOLD',
    maxSwipesPerDay: null, // Illimité
    maxLikesPerDay: null, // Illimité
    maxSuperLikesPerDay: 999, // Illimité pratiquement
    maxVideoDurationSeconds: 20,
    maxVideos: 10,
    canSeeWhoLikedYou: true,
    hasAdvancedFilters: true,
    hasNoAds: true,
    boostsPerMonth: 5,
  );

  /// Obtenir les limitations pour un plan donné
  static PlanLimits forPlan(String plan) {
    switch (plan.toLowerCase()) {
      case SubscriptionPlan.silver:
        return silverPlan;
      case SubscriptionPlan.gold:
        return goldPlan;
      case SubscriptionPlan.free:
      default:
        return freePlan;
    }
  }

  /// Vérifier si les swipes sont illimités
  bool get hasUnlimitedSwipes => maxSwipesPerDay == null;

  /// Vérifier si les likes sont illimités
  bool get hasUnlimitedLikes => maxLikesPerDay == null;

  /// Formater pour affichage
  String formatSwipesLimit() {
    return maxSwipesPerDay == null ? 'Illimité' : '$maxSwipesPerDay/jour';
  }

  String formatLikesLimit() {
    return maxLikesPerDay == null ? 'Illimité' : '$maxLikesPerDay/jour';
  }

  String formatSuperLikesLimit() {
    return maxSuperLikesPerDay >= 999 ? 'Illimité' : '$maxSuperLikesPerDay/jour';
  }

  String formatVideoLimit() {
    return '$maxVideos vidéo${maxVideos > 1 ? 's' : ''} (${maxVideoDurationSeconds}s max)';
  }
}
