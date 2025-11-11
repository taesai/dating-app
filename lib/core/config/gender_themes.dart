import 'package:flutter/material.dart';

/// Thèmes prédéfinis par genre/orientation
class GenderThemes {
  /// Thème pour les hommes (hétéro/bi)
  static final ThemeData menTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      primary: Colors.blue.shade700,
      secondary: Colors.cyan.shade600,
      tertiary: Colors.indigo.shade400,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue.shade700,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  static final ThemeData menThemeDark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
      primary: Colors.blue.shade400,
      secondary: Colors.cyan.shade400,
      tertiary: Colors.indigo.shade300,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue.shade900,
      foregroundColor: Colors.white,
    ),
  );

  /// Thème pour les femmes (hétéro/bi)
  static final ThemeData womenTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.pink,
      primary: Colors.pink.shade400,
      secondary: Colors.purple.shade400,
      tertiary: Colors.deepPurple.shade300,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.pink.shade400,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.pink.shade400,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  static final ThemeData womenThemeDark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.pink,
      brightness: Brightness.dark,
      primary: Colors.pink.shade300,
      secondary: Colors.purple.shade300,
      tertiary: Colors.deepPurple.shade200,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.pink.shade900,
      foregroundColor: Colors.white,
    ),
  );

  /// Thème LGBT+ (arc-en-ciel)
  static final ThemeData lgbtTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.purple,
      primary: Colors.purple.shade600,
      secondary: Colors.orange.shade500,
      tertiary: Colors.teal.shade400,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.purple.shade600,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.purple.shade600,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  static final ThemeData lgbtThemeDark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.purple,
      brightness: Brightness.dark,
      primary: Colors.purple.shade400,
      secondary: Colors.orange.shade400,
      tertiary: Colors.teal.shade300,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.purple.shade900,
      foregroundColor: Colors.white,
    ),
  );

  /// Thème neutre/universel
  static final ThemeData neutralTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      primary: Colors.teal.shade600,
      secondary: Colors.amber.shade600,
      tertiary: Colors.green.shade500,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.teal.shade600,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.teal.shade600,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  static final ThemeData neutralThemeDark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
      primary: Colors.teal.shade400,
      secondary: Colors.amber.shade400,
      tertiary: Colors.green.shade400,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.teal.shade900,
      foregroundColor: Colors.white,
    ),
  );

  /// Obtenir le thème basé sur le genre et l'orientation
  static ThemeData getThemeForGender(
    String gender,
    String? sexualOrientation,
    bool isDarkMode,
  ) {
    // Normaliser le genre
    final normalizedGender = gender.toLowerCase();
    final normalizedOrientation = sexualOrientation?.toLowerCase() ?? '';

    // LGBT+ (inclus toutes les orientations non-hétéro)
    if (normalizedOrientation.contains('gay') ||
        normalizedOrientation.contains('lesbian') ||
        normalizedOrientation.contains('queer') ||
        normalizedOrientation.contains('pansexuel') ||
        normalizedOrientation.contains('non-binaire')) {
      return isDarkMode ? lgbtThemeDark : lgbtTheme;
    }

    // Thème homme
    if (normalizedGender == 'homme' || normalizedGender == 'male') {
      return isDarkMode ? menThemeDark : menTheme;
    }

    // Thème femme
    if (normalizedGender == 'femme' || normalizedGender == 'female') {
      return isDarkMode ? womenThemeDark : womenTheme;
    }

    // Thème neutre par défaut
    return isDarkMode ? neutralThemeDark : neutralTheme;
  }

  /// Liste des thèmes disponibles pour sélection manuelle
  static const List<GenderThemeOption> availableThemes = [
    GenderThemeOption(
      id: 'men',
      name: 'Homme',
      description: 'Bleu et cyan',
      icon: Icons.man,
      primaryColor: Color(0xFF1976D2),
    ),
    GenderThemeOption(
      id: 'women',
      name: 'Femme',
      description: 'Rose et violet',
      icon: Icons.woman,
      primaryColor: Color(0xFFEC407A),
    ),
    GenderThemeOption(
      id: 'lgbt',
      name: 'LGBT+',
      description: 'Arc-en-ciel',
      icon: Icons.waving_hand,
      primaryColor: Color(0xFF9C27B0),
    ),
    GenderThemeOption(
      id: 'neutral',
      name: 'Neutre',
      description: 'Teal et ambre',
      icon: Icons.palette,
      primaryColor: Color(0xFF00897B),
    ),
  ];

  /// Obtenir le thème par ID
  static ThemeData getThemeById(String themeId, bool isDarkMode) {
    switch (themeId) {
      case 'men':
        return isDarkMode ? menThemeDark : menTheme;
      case 'women':
        return isDarkMode ? womenThemeDark : womenTheme;
      case 'lgbt':
        return isDarkMode ? lgbtThemeDark : lgbtTheme;
      case 'neutral':
        return isDarkMode ? neutralThemeDark : neutralTheme;
      default:
        return isDarkMode ? neutralThemeDark : neutralTheme;
    }
  }
}

/// Option de thème pour l'interface de sélection
class GenderThemeOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color primaryColor;

  const GenderThemeOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.primaryColor,
  });
}
