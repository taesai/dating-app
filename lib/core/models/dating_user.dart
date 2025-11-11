import 'dart:math';
import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import 'subscription_plan.dart' as sub;

class DatingUser {
  final String id;
  final String name;
  final String email;
  final int age;
  final String gender;
  final String bio;
  final double latitude;
  final double longitude;
  final List<String> interests;
  final List<String> photoUrls; // Stocke les fileIds
  final List<String> videoIds; // IDs des vidéos uploadées
  final DateTime createdAt;
  final bool isActive;
  final String subscriptionPlan; // 'free', 'silver', 'gold'
  final DateTime? subscriptionExpiresAt; // Date d'expiration de la souscription
  final DateTime? subscriptionStartedAt; // Date de début de la souscription
  final String? height; // Taille (en cm)
  final String? occupation; // Profession
  final String? education; // Niveau d'éducation
  final List<String> lookingFor; // Ce que la personne recherche
  final String? sexualOrientation; // Orientation sexuelle (Hétéro, Gay, Lesbienne, Bisexuel, Autre)
  final bool verified; // Profil vérifié
  final bool isProfileApproved; // Profil approuvé par l'admin

  // Nouveaux champs pour recherche avancée
  final String? maritalStatus; // Situation maritale (Célibataire, Divorcé(e), Veuf(ve), En couple, Compliqué)
  final List<String> sports; // Sports pratiqués
  final List<String> hobbies; // Hobbies/Loisirs
  final String? religion; // Religion (Catholique, Protestant, Musulman, Juif, Bouddhiste, Hindou, Athée, Autre)
  final String? bodyType; // Allure physique (Athlétique, Mince, Moyenne, Ronde, Musclé(e))
  final int? weight; // Poids en kg
  final String? country; // Pays
  final String? continent; // Continent (Afrique, Amérique, Asie, Europe, Océanie)
  final String? city; // Ville

  // Statistiques sociales
  final int? likeCount; // Nombre de likes reçus
  final int? matchCount; // Nombre de matches

  // Préférences de recherche
  final RangeValues? preferredAgeRange; // Tranche d'âge souhaitée
  final RangeValues? preferredHeightRange; // Tranche de taille souhaitée (en cm)
  final RangeValues? preferredWeightRange; // Tranche de poids souhaitée (en kg)
  final List<String>? preferredBodyTypes; // Types de corps souhaités
  final List<String>? preferredGenders; // Genres recherchés (homme, femme, autre, tous)
  final List<String>? preferredContinents; // Continents recherchés
  final List<String>? preferredCountries; // Pays recherchés
  final List<String>? preferredCities; // Villes recherchées
  final double? searchRadius; // Rayon de recherche en km

  // Getter pour obtenir les URLs complètes des photos
  List<String> get photoUrlsFull {
    final backend = BackendService();
    return photoUrls.map((fileId) => backend.getFileView(fileId)).toList();
  }

  /// Obtenir l'objet SubscriptionPlan complet
  sub.SubscriptionPlan get subscription {
    return sub.SubscriptionPlan(
      plan: subscriptionPlan,
      expiresAt: subscriptionExpiresAt,
      startedAt: subscriptionStartedAt,
    );
  }

  /// Obtenir le plan effectif (tenant compte de l'expiration)
  String get effectivePlan => subscription.effectivePlan;

  /// Obtenir les limitations du plan
  sub.PlanLimits get planLimits => subscription.limits;

  DatingUser({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.gender,
    required this.bio,
    required this.latitude,
    required this.longitude,
    required this.interests,
    required this.photoUrls,
    required this.videoIds,
    required this.createdAt,
    required this.isActive,
    this.subscriptionPlan = 'free',
    this.subscriptionExpiresAt,
    this.subscriptionStartedAt,
    this.height,
    this.occupation,
    this.education,
    this.lookingFor = const [],
    this.sexualOrientation,
    this.verified = false,
    this.isProfileApproved = false,
    // Nouveaux champs
    this.maritalStatus,
    this.sports = const [],
    this.hobbies = const [],
    this.religion,
    this.bodyType,
    this.weight,
    this.country,
    this.continent,
    this.city,
    this.likeCount,
    this.matchCount,
    this.preferredAgeRange,
    this.preferredHeightRange,
    this.preferredWeightRange,
    this.preferredBodyTypes,
    this.preferredGenders,
    this.preferredContinents,
    this.preferredCountries,
    this.preferredCities,
    this.searchRadius,
  });

  factory DatingUser.fromJson(Map<String, dynamic> json) {
    try {
      // Helper pour convertir les listes en filtrant les null
      List<String> _safeListFrom(dynamic value) {
        if (value == null) return [];
        if (value is! List) return [];
        return value.where((e) => e != null).map((e) => e.toString()).toList();
      }

      // Helper pour parser RangeValues
      RangeValues? _parseRangeValues(dynamic value) {
        if (value == null) return null;
        if (value is Map) {
          final start = (value['start'] ?? 0).toDouble();
          final end = (value['end'] ?? 100).toDouble();
          return RangeValues(start, end);
        }
        return null;
      }

      // Helper pour parser DateTime (gère string et array)
      DateTime? _parseDateTime(dynamic value) {
        if (value == null) return null;

        // Si c'est un array vide ou prendre le premier élément
        if (value is List) {
          if (value.isEmpty) return null;
          value = value.first;
        }

        final str = value.toString().trim();
        if (str.isEmpty || str == 'null' || str == '[]') return null;

        try {
          return DateTime.parse(str);
        } catch (e) {
          // Ignorer silencieusement les erreurs de parsing
          return null;
        }
      }

      return DatingUser(
        id: json['\$id'] ?? json['id'] ?? '', // Support backend local (id) et Appwrite ($id)
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        age: json['age'] ?? 0,
        gender: json['gender'] ?? '',
        bio: json['bio'] ?? '',
        latitude: (json['latitude'] ?? 0.0).toDouble(),
        longitude: (json['longitude'] ?? 0.0).toDouble(),
        interests: _safeListFrom(json['interests']),
        photoUrls: _safeListFrom(json['photoUrls']),
        videoIds: _safeListFrom(json['videoIds']),
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        isActive: json['isActive'] ?? true,
        subscriptionPlan: (json['subscriptionPlan']?.toString().toLowerCase()?.isNotEmpty == true)
            ? json['subscriptionPlan'].toString().toLowerCase()
            : 'free',
        subscriptionExpiresAt: _parseDateTime(json['subscriptionExpiresAt']),
        subscriptionStartedAt: _parseDateTime(json['subscriptionStartedAt']),
        height: json['height'],
        occupation: json['occupation'],
        education: json['education'],
        lookingFor: _safeListFrom(json['lookingFor']),
        sexualOrientation: json['sexualOrientation'],
        verified: json['verified'] ?? false,
        isProfileApproved: json['isProfileApproved'] ?? false,
        // Nouveaux champs
        maritalStatus: json['maritalStatus'],
        sports: _safeListFrom(json['sports']),
        hobbies: _safeListFrom(json['hobbies']),
        religion: json['religion'],
        bodyType: json['bodyType'],
        weight: json['weight'],
        country: json['country'],
        continent: json['continent'],
        city: json['city'],
        likeCount: json['likeCount'] ?? 0,
        matchCount: json['matchCount'] ?? 0,
        preferredAgeRange: _parseRangeValues(json['preferredAgeRange']),
        preferredHeightRange: _parseRangeValues(json['preferredHeightRange']),
        preferredWeightRange: _parseRangeValues(json['preferredWeightRange']),
        preferredBodyTypes: _safeListFrom(json['preferredBodyTypes']),
        preferredGenders: _safeListFrom(json['preferredGenders']),
        preferredContinents: _safeListFrom(json['preferredContinents']),
        preferredCountries: _safeListFrom(json['preferredCountries']),
        preferredCities: _safeListFrom(json['preferredCities']),
        searchRadius: json['searchRadius']?.toDouble(),
      );
    } catch (e, stackTrace) {
      print('❌ ERREUR DatingUser.fromJson:');
      print('JSON reçu: $json');
      print('Erreur: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'gender': gender,
      'bio': bio,
      'latitude': latitude,
      'longitude': longitude,
      'interests': interests,
      'photoUrls': photoUrls,
      'videoIds': videoIds,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'subscriptionPlan': subscriptionPlan,
      'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
      'subscriptionStartedAt': subscriptionStartedAt?.toIso8601String(),
      'height': height,
      'occupation': occupation,
      'education': education,
      'lookingFor': lookingFor,
      'sexualOrientation': sexualOrientation,
      'verified': verified,
      'isProfileApproved': isProfileApproved,
      // Nouveaux champs
      'maritalStatus': maritalStatus,
      'sports': sports,
      'hobbies': hobbies,
      'religion': religion,
      'bodyType': bodyType,
      'weight': weight,
      'country': country,
      'continent': continent,
      'city': city,
      'likeCount': likeCount,
      'matchCount': matchCount,
      'preferredAgeRange': preferredAgeRange != null ? {
        'start': preferredAgeRange!.start,
        'end': preferredAgeRange!.end,
      } : null,
      'preferredHeightRange': preferredHeightRange != null ? {
        'start': preferredHeightRange!.start,
        'end': preferredHeightRange!.end,
      } : null,
      'preferredWeightRange': preferredWeightRange != null ? {
        'start': preferredWeightRange!.start,
        'end': preferredWeightRange!.end,
      } : null,
      'preferredBodyTypes': preferredBodyTypes,
      'preferredGenders': preferredGenders,
      'preferredContinents': preferredContinents,
      'preferredCountries': preferredCountries,
      'preferredCities': preferredCities,
      'searchRadius': searchRadius,
    };
  }

  // Calculer la distance entre deux utilisateurs (en km)
  double distanceTo(DatingUser other) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    double lat1 = latitude * 0.017453292519943295; // Conversion en radians
    double lat2 = other.latitude * 0.017453292519943295;
    double lon1 = longitude * 0.017453292519943295;
    double lon2 = other.longitude * 0.017453292519943295;

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }
}