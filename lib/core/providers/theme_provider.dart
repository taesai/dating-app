import 'package:dating_app/core/providers/auth_provider.dart';
import 'package:dating_app/core/config/gender_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// État du thème (clair ou sombre + thème genre + couleurs personnalisées)
class ThemeState {
  final ThemeMode themeMode;
  final bool isDark;
  final String genderThemeId; // ID du thème par genre
  final Color? customPrimaryColor;
  final Color? customSecondaryColor;
  final Color? customTertiaryColor;
  final bool isCustomTheme;

  const ThemeState({
    this.themeMode = ThemeMode.light,
    this.isDark = false,
    this.genderThemeId = 'neutral',
    this.customPrimaryColor,
    this.customSecondaryColor,
    this.customTertiaryColor,
    this.isCustomTheme = false,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? isDark,
    String? genderThemeId,
    Color? customPrimaryColor,
    Color? customSecondaryColor,
    Color? customTertiaryColor,
    bool? isCustomTheme,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isDark: isDark ?? this.isDark,
      genderThemeId: genderThemeId ?? this.genderThemeId,
      customPrimaryColor: customPrimaryColor ?? this.customPrimaryColor,
      customSecondaryColor: customSecondaryColor ?? this.customSecondaryColor,
      customTertiaryColor: customTertiaryColor ?? this.customTertiaryColor,
      isCustomTheme: isCustomTheme ?? this.isCustomTheme,
    );
  }
}

/// Notifier pour gérer le thème
class ThemeNotifier extends StateNotifier<ThemeState> {
  final SharedPreferences _prefs;
  static const String _themeKey = 'theme_mode';
  static const String _genderThemeKey = 'gender_theme_id';

  ThemeNotifier(this._prefs) : super(const ThemeState()) {
    _loadTheme();
  }

  /// Charger le thème sauvegardé
  Future<void> _loadTheme() async {
    final isDark = _prefs.getBool(_themeKey) ?? false;
    final genderThemeId = _prefs.getString(_genderThemeKey) ?? 'neutral';
    final isCustom = _prefs.getBool('is_custom_theme') ?? false;

    if (isCustom) {
      final primaryValue = _prefs.getInt('custom_primary_color');
      final secondaryValue = _prefs.getInt('custom_secondary_color');
      final tertiaryValue = _prefs.getInt('custom_tertiary_color');

      if (primaryValue != null && secondaryValue != null && tertiaryValue != null) {
        state = ThemeState(
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          isDark: isDark,
          genderThemeId: 'custom',
          customPrimaryColor: Color(primaryValue),
          customSecondaryColor: Color(secondaryValue),
          customTertiaryColor: Color(tertiaryValue),
          isCustomTheme: true,
        );
        return;
      }
    }

    state = ThemeState(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      isDark: isDark,
      genderThemeId: genderThemeId,
    );
  }

  /// Basculer entre clair et sombre
  Future<void> toggleTheme() async {
    final newIsDark = !state.isDark;
    await _prefs.setBool(_themeKey, newIsDark);
    state = state.copyWith(
      themeMode: newIsDark ? ThemeMode.dark : ThemeMode.light,
      isDark: newIsDark,
    );
  }

  /// Définir un thème spécifique
  Future<void> setTheme(bool isDark) async {
    await _prefs.setBool(_themeKey, isDark);
    state = state.copyWith(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      isDark: isDark,
    );
  }

  /// Changer le thème par genre
  Future<void> setGenderTheme(String themeId) async {
    await _prefs.setString(_genderThemeKey, themeId);
    // Désactiver le thème personnalisé si on sélectionne un thème prédéfini
    if (themeId != 'custom') {
      await _prefs.setBool('is_custom_theme', false);
      state = ThemeState(
        themeMode: state.themeMode,
        isDark: state.isDark,
        genderThemeId: themeId,
        isCustomTheme: false,
      );
    } else {
      state = state.copyWith(genderThemeId: themeId);
    }
  }

  /// Définir automatiquement le thème basé sur le genre de l'utilisateur
  Future<void> setThemeFromUserGender(String gender, String? sexualOrientation) async {
    String themeId = 'neutral';

    final normalizedGender = gender.toLowerCase();
    final normalizedOrientation = sexualOrientation?.toLowerCase() ?? '';

    // LGBT+
    if (normalizedOrientation.contains('gay') ||
        normalizedOrientation.contains('lesbian') ||
        normalizedOrientation.contains('queer') ||
        normalizedOrientation.contains('pansexuel') ||
        normalizedOrientation.contains('non-binaire')) {
      themeId = 'lgbt';
    }
    // Homme
    else if (normalizedGender == 'homme' || normalizedGender == 'male') {
      themeId = 'men';
    }
    // Femme
    else if (normalizedGender == 'femme' || normalizedGender == 'female') {
      themeId = 'women';
    }

    await setGenderTheme(themeId);
  }

  /// Définir un thème personnalisé avec des couleurs spécifiques
  Future<void> setCustomTheme(
    Color primaryColor,
    Color secondaryColor,
    Color tertiaryColor,
    bool isDark,
  ) async {
    // Sauvegarder les couleurs en SharedPreferences
    await _prefs.setInt('custom_primary_color', primaryColor.value);
    await _prefs.setInt('custom_secondary_color', secondaryColor.value);
    await _prefs.setInt('custom_tertiary_color', tertiaryColor.value);
    await _prefs.setBool('is_custom_theme', true);
    await _prefs.setBool(_themeKey, isDark);

    state = ThemeState(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      isDark: isDark,
      genderThemeId: 'custom',
      customPrimaryColor: primaryColor,
      customSecondaryColor: secondaryColor,
      customTertiaryColor: tertiaryColor,
      isCustomTheme: true,
    );
  }

  /// Charger un thème personnalisé sauvegardé
  Future<void> _loadCustomTheme() async {
    final isCustom = _prefs.getBool('is_custom_theme') ?? false;
    if (isCustom) {
      final primaryValue = _prefs.getInt('custom_primary_color');
      final secondaryValue = _prefs.getInt('custom_secondary_color');
      final tertiaryValue = _prefs.getInt('custom_tertiary_color');

      if (primaryValue != null && secondaryValue != null && tertiaryValue != null) {
        state = state.copyWith(
          customPrimaryColor: Color(primaryValue),
          customSecondaryColor: Color(secondaryValue),
          customTertiaryColor: Color(tertiaryValue),
          isCustomTheme: true,
          genderThemeId: 'custom',
        );
      }
    }
  }

  /// Réinitialiser le thème au thème par défaut
  Future<void> resetTheme() async {
    await _prefs.remove('is_custom_theme');
    await _prefs.remove('custom_primary_color');
    await _prefs.remove('custom_secondary_color');
    await _prefs.remove('custom_tertiary_color');
    await _prefs.setString(_genderThemeKey, 'neutral');

    state = ThemeState(
      themeMode: state.themeMode,
      isDark: state.isDark,
      genderThemeId: 'neutral',
      isCustomTheme: false,
    );
  }
}

/// Provider du thème
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).maybeWhen(
        data: (prefs) => prefs,
        orElse: () => throw Exception('SharedPreferences not initialized'),
      );
  return ThemeNotifier(prefs);
});

/// Thèmes de l'application (utilise maintenant GenderThemes)
class AppTheme {
  /// Obtenir le thème clair basé sur le genre
  static ThemeData lightTheme(String genderThemeId) {
    return GenderThemes.getThemeById(genderThemeId, false);
  }

  /// Obtenir le thème sombre basé sur le genre
  static ThemeData darkTheme(String genderThemeId) {
    return GenderThemes.getThemeById(genderThemeId, true);
  }

  /// Obtenir le thème selon l'état actuel
  static ThemeData getTheme(ThemeState themeState) {
    // Si thème personnalisé, utiliser les couleurs custom
    if (themeState.isCustomTheme &&
        themeState.customPrimaryColor != null &&
        themeState.customSecondaryColor != null &&
        themeState.customTertiaryColor != null) {
      return _buildCustomTheme(
        themeState.customPrimaryColor!,
        themeState.customSecondaryColor!,
        themeState.customTertiaryColor!,
        themeState.isDark,
      );
    }

    // Sinon, utiliser le thème par genre
    return GenderThemes.getThemeById(
      themeState.genderThemeId,
      themeState.isDark,
    );
  }

  /// Construire un thème personnalisé avec les couleurs choisies
  static ThemeData _buildCustomTheme(
    Color primary,
    Color secondary,
    Color tertiary,
    bool isDark,
  ) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: secondary,
      tertiary: tertiary,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
      ),
      cardTheme: CardTheme(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 2,
      ),
    );
  }
}
