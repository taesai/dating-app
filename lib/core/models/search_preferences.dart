import 'package:flutter/material.dart';

class SearchPreferences {
  final RangeValues ageRange;
  final double maxDistance;
  final String? gender;
  final String? sexualOrientation;
  final List<String> interests;
  final List<String> lookingFor;
  final int? minHeight;
  final int? maxHeight;
  final List<String> continents;
  final List<String> countries;
  final List<String> cities;

  SearchPreferences({
    this.ageRange = const RangeValues(18, 99),
    this.maxDistance = 20000, // 20,000 km par défaut (mondial)
    this.gender,
    this.sexualOrientation,
    this.interests = const [],
    this.lookingFor = const [],
    this.minHeight,
    this.maxHeight,
    this.continents = const [],
    this.countries = const [],
    this.cities = const [],
  });

  SearchPreferences copyWith({
    RangeValues? ageRange,
    double? maxDistance,
    String? gender,
    String? sexualOrientation,
    List<String>? interests,
    List<String>? lookingFor,
    int? minHeight,
    int? maxHeight,
    List<String>? continents,
    List<String>? countries,
    List<String>? cities,
  }) {
    return SearchPreferences(
      ageRange: ageRange ?? this.ageRange,
      maxDistance: maxDistance ?? this.maxDistance,
      gender: gender ?? this.gender,
      sexualOrientation: sexualOrientation ?? this.sexualOrientation,
      interests: interests ?? this.interests,
      lookingFor: lookingFor ?? this.lookingFor,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      continents: continents ?? this.continents,
      countries: countries ?? this.countries,
      cities: cities ?? this.cities,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ageMin': ageRange.start.toInt(),
      'ageMax': ageRange.end.toInt(),
      'maxDistance': maxDistance,
      'gender': gender,
      'sexualOrientation': sexualOrientation,
      'interests': interests,
      'lookingFor': lookingFor,
      'minHeight': minHeight,
      'maxHeight': maxHeight,
      'continents': continents,
      'countries': countries,
      'cities': cities,
    };
  }

  factory SearchPreferences.fromJson(Map<String, dynamic> json) {
    return SearchPreferences(
      ageRange: RangeValues(
        (json['ageMin'] as num?)?.toDouble() ?? 18,
        (json['ageMax'] as num?)?.toDouble() ?? 99,
      ),
      maxDistance: (json['maxDistance'] as num?)?.toDouble() ?? 20000,
      gender: json['gender'],
      sexualOrientation: json['sexualOrientation'],
      interests: List<String>.from(json['interests'] ?? []),
      lookingFor: List<String>.from(json['lookingFor'] ?? []),
      minHeight: json['minHeight'],
      maxHeight: json['maxHeight'],
      continents: List<String>.from(json['continents'] ?? []),
      countries: List<String>.from(json['countries'] ?? []),
      cities: List<String>.from(json['cities'] ?? []),
    );
  }
}
