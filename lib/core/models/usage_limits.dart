/// Modèle pour suivre l'utilisation quotidienne de l'utilisateur
class UsageLimits {
  final String userId;
  final DateTime date; // Date du jour (midnight UTC)

  // Compteurs d'utilisation
  int swipesCount;
  int likesCount;
  int superLikesCount;
  int boostsUsed;

  UsageLimits({
    required this.userId,
    required this.date,
    this.swipesCount = 0,
    this.likesCount = 0,
    this.superLikesCount = 0,
    this.boostsUsed = 0,
  });

  /// Vérifier si c'est aujourd'hui
  bool get isToday {
    final now = DateTime.now().toUtc();
    final today = DateTime(now.year, now.month, now.day);
    final usageDate = DateTime(date.year, date.month, date.day);
    return today.isAtSameMomentAs(usageDate);
  }

  /// Réinitialiser les compteurs (nouveau jour)
  void reset() {
    swipesCount = 0;
    likesCount = 0;
    superLikesCount = 0;
    // boostsUsed ne se réinitialise pas quotidiennement
  }

  /// Incrémenter le compteur de swipes
  void incrementSwipes() {
    swipesCount++;
  }

  /// Incrémenter le compteur de likes
  void incrementLikes() {
    likesCount++;
  }

  /// Incrémenter le compteur de super likes
  void incrementSuperLikes() {
    superLikesCount++;
  }

  /// Incrémenter le compteur de boosts
  void incrementBoosts() {
    boostsUsed++;
  }

  /// Convertir en JSON pour stockage
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': date.toIso8601String(),
      'swipesCount': swipesCount,
      'likesCount': likesCount,
      'superLikesCount': superLikesCount,
      'boostsUsed': boostsUsed,
    };
  }

  /// Créer depuis JSON
  factory UsageLimits.fromJson(Map<String, dynamic> json) {
    return UsageLimits(
      userId: json['userId'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now().toUtc(),
      swipesCount: json['swipesCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      superLikesCount: json['superLikesCount'] ?? 0,
      boostsUsed: json['boostsUsed'] ?? 0,
    );
  }

  /// Créer une nouvelle instance pour aujourd'hui
  factory UsageLimits.today(String userId) {
    final now = DateTime.now().toUtc();
    final today = DateTime(now.year, now.month, now.day);
    return UsageLimits(
      userId: userId,
      date: today,
    );
  }

  /// Copier avec modifications
  UsageLimits copyWith({
    String? userId,
    DateTime? date,
    int? swipesCount,
    int? likesCount,
    int? superLikesCount,
    int? boostsUsed,
  }) {
    return UsageLimits(
      userId: userId ?? this.userId,
      date: date ?? this.date,
      swipesCount: swipesCount ?? this.swipesCount,
      likesCount: likesCount ?? this.likesCount,
      superLikesCount: superLikesCount ?? this.superLikesCount,
      boostsUsed: boostsUsed ?? this.boostsUsed,
    );
  }

  @override
  String toString() {
    return 'UsageLimits(userId: $userId, date: $date, swipes: $swipesCount, likes: $likesCount, superLikes: $superLikesCount, boosts: $boostsUsed)';
  }
}
