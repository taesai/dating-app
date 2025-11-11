/// Modèle pour les filtres de recherche avancés
class SearchFilters {
  // Filtres de base
  final int? minAge;
  final int? maxAge;
  final List<String> genders;
  final double? maxDistance; // en km

  // Filtres d'apparence
  final List<String> bodyTypes;
  final int? minHeight; // en cm
  final int? maxHeight;

  // Filtres de style de vie
  final List<String> interests;
  final List<String> sports;
  final List<String> hobbies;
  final List<String> lookingFor;

  // Filtres de valeurs
  final List<String> religions;
  final List<String> maritalStatuses;
  final List<String> educationLevels;
  final String? childrenPreference; // 'yes', 'no', 'maybe', 'any'

  // Filtres avancés
  final bool? isPremium;
  final bool? hasPhotos;
  final bool? hasVerifiedPhotos;
  final bool? isActive; // actif dans les 7 derniers jours
  final int? minCompatibilityScore; // 0-100

  SearchFilters({
    this.minAge,
    this.maxAge,
    this.genders = const [],
    this.maxDistance,
    this.bodyTypes = const [],
    this.minHeight,
    this.maxHeight,
    this.interests = const [],
    this.sports = const [],
    this.hobbies = const [],
    this.lookingFor = const [],
    this.religions = const [],
    this.maritalStatuses = const [],
    this.educationLevels = const [],
    this.childrenPreference,
    this.isPremium,
    this.hasPhotos,
    this.hasVerifiedPhotos,
    this.isActive,
    this.minCompatibilityScore,
  });

  SearchFilters copyWith({
    int? minAge,
    int? maxAge,
    List<String>? genders,
    double? maxDistance,
    List<String>? bodyTypes,
    int? minHeight,
    int? maxHeight,
    List<String>? interests,
    List<String>? sports,
    List<String>? hobbies,
    List<String>? lookingFor,
    List<String>? religions,
    List<String>? maritalStatuses,
    List<String>? educationLevels,
    String? childrenPreference,
    bool? isPremium,
    bool? hasPhotos,
    bool? hasVerifiedPhotos,
    bool? isActive,
    int? minCompatibilityScore,
  }) {
    return SearchFilters(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      genders: genders ?? this.genders,
      maxDistance: maxDistance ?? this.maxDistance,
      bodyTypes: bodyTypes ?? this.bodyTypes,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      interests: interests ?? this.interests,
      sports: sports ?? this.sports,
      hobbies: hobbies ?? this.hobbies,
      lookingFor: lookingFor ?? this.lookingFor,
      religions: religions ?? this.religions,
      maritalStatuses: maritalStatuses ?? this.maritalStatuses,
      educationLevels: educationLevels ?? this.educationLevels,
      childrenPreference: childrenPreference ?? this.childrenPreference,
      isPremium: isPremium ?? this.isPremium,
      hasPhotos: hasPhotos ?? this.hasPhotos,
      hasVerifiedPhotos: hasVerifiedPhotos ?? this.hasVerifiedPhotos,
      isActive: isActive ?? this.isActive,
      minCompatibilityScore: minCompatibilityScore ?? this.minCompatibilityScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minAge': minAge,
      'maxAge': maxAge,
      'genders': genders,
      'maxDistance': maxDistance,
      'bodyTypes': bodyTypes,
      'minHeight': minHeight,
      'maxHeight': maxHeight,
      'interests': interests,
      'sports': sports,
      'hobbies': hobbies,
      'lookingFor': lookingFor,
      'religions': religions,
      'maritalStatuses': maritalStatuses,
      'educationLevels': educationLevels,
      'childrenPreference': childrenPreference,
      'isPremium': isPremium,
      'hasPhotos': hasPhotos,
      'hasVerifiedPhotos': hasVerifiedPhotos,
      'isActive': isActive,
      'minCompatibilityScore': minCompatibilityScore,
    };
  }

  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    return SearchFilters(
      minAge: json['minAge'],
      maxAge: json['maxAge'],
      genders: json['genders'] != null ? List<String>.from(json['genders']) : [],
      maxDistance: json['maxDistance']?.toDouble(),
      bodyTypes: json['bodyTypes'] != null ? List<String>.from(json['bodyTypes']) : [],
      minHeight: json['minHeight'],
      maxHeight: json['maxHeight'],
      interests: json['interests'] != null ? List<String>.from(json['interests']) : [],
      sports: json['sports'] != null ? List<String>.from(json['sports']) : [],
      hobbies: json['hobbies'] != null ? List<String>.from(json['hobbies']) : [],
      lookingFor: json['lookingFor'] != null ? List<String>.from(json['lookingFor']) : [],
      religions: json['religions'] != null ? List<String>.from(json['religions']) : [],
      maritalStatuses: json['maritalStatuses'] != null ? List<String>.from(json['maritalStatuses']) : [],
      educationLevels: json['educationLevels'] != null ? List<String>.from(json['educationLevels']) : [],
      childrenPreference: json['childrenPreference'],
      isPremium: json['isPremium'],
      hasPhotos: json['hasPhotos'],
      hasVerifiedPhotos: json['hasVerifiedPhotos'],
      isActive: json['isActive'],
      minCompatibilityScore: json['minCompatibilityScore'],
    );
  }

  /// Filtres par défaut (tous les utilisateurs)
  factory SearchFilters.defaultFilters() {
    return SearchFilters(
      minAge: 18,
      maxAge: 99,
      maxDistance: 50,
    );
  }

  /// Nombre de filtres actifs
  int get activeFiltersCount {
    int count = 0;
    if (minAge != null && minAge != 18) count++;
    if (maxAge != null && maxAge != 99) count++;
    if (genders.isNotEmpty) count++;
    if (maxDistance != null && maxDistance != 50) count++;
    if (bodyTypes.isNotEmpty) count++;
    if (minHeight != null) count++;
    if (maxHeight != null) count++;
    if (interests.isNotEmpty) count++;
    if (sports.isNotEmpty) count++;
    if (hobbies.isNotEmpty) count++;
    if (lookingFor.isNotEmpty) count++;
    if (religions.isNotEmpty) count++;
    if (maritalStatuses.isNotEmpty) count++;
    if (educationLevels.isNotEmpty) count++;
    if (childrenPreference != null && childrenPreference != 'any') count++;
    if (isPremium != null) count++;
    if (hasPhotos != null) count++;
    if (hasVerifiedPhotos != null) count++;
    if (isActive != null) count++;
    if (minCompatibilityScore != null) count++;
    return count;
  }

  /// Réinitialiser tous les filtres
  SearchFilters reset() {
    return SearchFilters.defaultFilters();
  }
}

/// Options prédéfinies pour les filtres
class FilterOptions {
  static const List<String> bodyTypes = [
    'Athlétique',
    'Mince',
    'Moyenne',
    'Ronde',
    'Musclé(e)',
  ];

  static const List<String> religions = [
    'Catholique',
    'Protestant',
    'Musulman',
    'Juif',
    'Bouddhiste',
    'Hindou',
    'Athée',
    'Autre',
  ];

  static const List<String> maritalStatuses = [
    'Célibataire',
    'Divorcé(e)',
    'Veuf(ve)',
    'En couple',
    'Compliqué',
  ];

  static const List<String> educationLevels = [
    'Lycée',
    'Bac',
    'Bac+2',
    'Bac+3',
    'Bac+5',
    'Doctorat',
  ];

  static const List<String> lookingForOptions = [
    'Relation sérieuse',
    'Rencontre amicale',
    'Aventure',
    'Pas sûr(e)',
  ];

  static const List<String> childrenPreferences = [
    'any',
    'yes',
    'maybe',
    'no',
  ];

  static String getChildrenPreferenceLabel(String pref) {
    switch (pref) {
      case 'yes':
        return 'Oui, certainement';
      case 'maybe':
        return 'Peut-être un jour';
      case 'no':
        return 'Non, jamais';
      case 'any':
      default:
        return 'Peu importe';
    }
  }
}
