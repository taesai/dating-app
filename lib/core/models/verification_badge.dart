import 'package:flutter/material.dart';

/// Types de badges de vérification
enum BadgeType {
  verified, // Profil vérifié (identité)
  premium, // Utilisateur premium
  popular, // Profil populaire
  photoVerified, // Photos vérifiées
  activeUser, // Utilisateur actif
  earlyAdopter, // Utilisateur de la première heure
}

/// Modèle de badge de vérification
class VerificationBadge {
  final BadgeType type;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final DateTime? awardedAt;

  VerificationBadge({
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    this.awardedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'label': label,
      'description': description,
      'awardedAt': awardedAt?.toIso8601String(),
    };
  }

  factory VerificationBadge.fromJson(Map<String, dynamic> json) {
    final type = BadgeType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => BadgeType.verified,
    );

    return VerificationBadge(
      type: type,
      label: json['label'],
      description: json['description'],
      icon: _getIconForType(type),
      color: _getColorForType(type),
      awardedAt: json['awardedAt'] != null ? DateTime.parse(json['awardedAt']) : null,
    );
  }

  static IconData _getIconForType(BadgeType type) {
    switch (type) {
      case BadgeType.verified:
        return Icons.verified;
      case BadgeType.premium:
        return Icons.workspace_premium;
      case BadgeType.popular:
        return Icons.local_fire_department;
      case BadgeType.photoVerified:
        return Icons.photo_camera;
      case BadgeType.activeUser:
        return Icons.favorite;
      case BadgeType.earlyAdopter:
        return Icons.star;
    }
  }

  static Color _getColorForType(BadgeType type) {
    switch (type) {
      case BadgeType.verified:
        return const Color(0xFF1DA1F2); // Bleu
      case BadgeType.premium:
        return const Color(0xFFFFD700); // Or
      case BadgeType.popular:
        return const Color(0xFFFF4500); // Rouge-orange
      case BadgeType.photoVerified:
        return const Color(0xFF00C853); // Vert
      case BadgeType.activeUser:
        return const Color(0xFFE91E63); // Rose
      case BadgeType.earlyAdopter:
        return const Color(0xFF9C27B0); // Violet
    }
  }
}

/// Collection de badges prédéfinis
class BadgeDefinitions {
  static VerificationBadge get verified => VerificationBadge(
        type: BadgeType.verified,
        label: 'Vérifié',
        description: 'Identité vérifiée par l\'équipe',
        icon: Icons.verified,
        color: const Color(0xFF1DA1F2),
      );

  static VerificationBadge get premium => VerificationBadge(
        type: BadgeType.premium,
        label: 'Premium',
        description: 'Membre Premium',
        icon: Icons.workspace_premium,
        color: const Color(0xFFFFD700),
      );

  static VerificationBadge get popular => VerificationBadge(
        type: BadgeType.popular,
        label: 'Populaire',
        description: 'Profil très apprécié',
        icon: Icons.local_fire_department,
        color: const Color(0xFFFF4500),
      );

  static VerificationBadge get photoVerified => VerificationBadge(
        type: BadgeType.photoVerified,
        label: 'Photos vérifiées',
        description: 'Photos authentifiées',
        icon: Icons.photo_camera,
        color: const Color(0xFF00C853),
      );

  static VerificationBadge get activeUser => VerificationBadge(
        type: BadgeType.activeUser,
        label: 'Actif',
        description: 'Utilisateur très actif',
        icon: Icons.favorite,
        color: const Color(0xFFE91E63),
      );

  static VerificationBadge get earlyAdopter => VerificationBadge(
        type: BadgeType.earlyAdopter,
        label: 'Pionnier',
        description: 'Parmi les premiers utilisateurs',
        icon: Icons.star,
        color: const Color(0xFF9C27B0),
      );

  static VerificationBadge? getBadge(BadgeType type) {
    switch (type) {
      case BadgeType.verified:
        return verified;
      case BadgeType.premium:
        return premium;
      case BadgeType.popular:
        return popular;
      case BadgeType.photoVerified:
        return photoVerified;
      case BadgeType.activeUser:
        return activeUser;
      case BadgeType.earlyAdopter:
        return earlyAdopter;
    }
  }

  static List<VerificationBadge> getAllBadges() {
    return [
      verified,
      premium,
      popular,
      photoVerified,
      activeUser,
      earlyAdopter,
    ];
  }
}

/// Extension sur DatingUser pour gérer les badges
class BadgeHelper {
  /// Vérifier si un utilisateur a un badge spécifique
  static bool hasBadge(List<String>? badges, BadgeType type) {
    if (badges == null) return false;
    return badges.contains(type.name);
  }

  /// Ajouter un badge à un utilisateur
  static List<String> addBadge(List<String>? badges, BadgeType type) {
    final currentBadges = badges ?? [];
    if (!currentBadges.contains(type.name)) {
      return [...currentBadges, type.name];
    }
    return currentBadges;
  }

  /// Retirer un badge d'un utilisateur
  static List<String> removeBadge(List<String>? badges, BadgeType type) {
    final currentBadges = badges ?? [];
    return currentBadges.where((b) => b != type.name).toList();
  }

  /// Obtenir tous les badges d'un utilisateur
  static List<VerificationBadge> getUserBadges(List<String>? badges) {
    if (badges == null) return [];

    return badges
        .map((badgeName) {
          try {
            final type = BadgeType.values.firstWhere((e) => e.name == badgeName);
            return BadgeDefinitions.getBadge(type);
          } catch (e) {
            return null;
          }
        })
        .whereType<VerificationBadge>()
        .toList();
  }

  /// Déterminer automatiquement les badges qu'un utilisateur devrait avoir
  static List<String> autoAwardBadges({
    required bool isPremium,
    required int likesReceived,
    required int profileViews,
    required DateTime accountCreatedAt,
    bool hasVerifiedPhotos = false,
    int daysActive = 0,
  }) {
    final List<String> badges = [];

    // Badge Premium
    if (isPremium) {
      badges.add(BadgeType.premium.name);
    }

    // Badge Populaire (plus de 100 likes reçus)
    if (likesReceived > 100) {
      badges.add(BadgeType.popular.name);
    }

    // Badge Photos vérifiées
    if (hasVerifiedPhotos) {
      badges.add(BadgeType.photoVerified.name);
    }

    // Badge Utilisateur actif (connecté au moins 20 jours dans les 30 derniers jours)
    if (daysActive >= 20) {
      badges.add(BadgeType.activeUser.name);
    }

    // Badge Early Adopter (compte créé dans les 3 premiers mois)
    final appLaunchDate = DateTime(2024, 1, 1); // Date de lancement de l'app
    final threeMonthsAfterLaunch = appLaunchDate.add(const Duration(days: 90));
    if (accountCreatedAt.isBefore(threeMonthsAfterLaunch)) {
      badges.add(BadgeType.earlyAdopter.name);
    }

    return badges;
  }
}
