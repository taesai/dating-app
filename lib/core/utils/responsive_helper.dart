import 'package:flutter/material.dart';

/// Helper class pour gérer le design responsive
class ResponsiveHelper {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Détermine si l'écran est mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Détermine si l'écran est tablette
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Détermine si l'écran est desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Retourne le type d'appareil
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < desktopBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Retourne une valeur selon le type d'appareil
  static T valueByDevice<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Largeur maximale pour le contenu sur desktop
  static double getMaxContentWidth(BuildContext context) {
    return isDesktop(context) ? 1200 : double.infinity;
  }

  /// Padding adaptatif
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    return EdgeInsets.all(valueByDevice(
      context: context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    ));
  }

  /// Nombre de colonnes pour une grille
  static int getGridColumns(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );
  }

  /// Taille de police adaptative
  static double getFontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return valueByDevice(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Largeur de la navigation rail pour desktop
  static const double navigationRailWidth = 80.0;
  static const double navigationRailWidthExtended = 200.0;

  /// Durée d'animation adaptative
  static Duration getAnimationDuration(BuildContext context, {
    Duration? mobile,
    Duration? tablet,
    Duration? desktop,
  }) {
    return valueByDevice(
      context: context,
      mobile: mobile ?? const Duration(milliseconds: 300),
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Taille des icônes adaptative
  static double getIconSize(BuildContext context, {
    double mobile = 24.0,
    double? tablet,
    double? desktop,
  }) {
    return valueByDevice(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.5,
    );
  }

  /// Taille des boutons adaptative
  static double getButtonSize(BuildContext context, {
    double mobile = 50.0,
    double? tablet,
    double? desktop,
  }) {
    return valueByDevice(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.3,
    );
  }

  /// Largeur du dialog adaptative
  static double getDialogWidth(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: MediaQuery.of(context).size.width * 0.9,
      tablet: 500.0,
      desktop: 600.0,
    );
  }

  /// Hauteur des cartes adaptative
  static double getCardHeight(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: MediaQuery.of(context).size.height * 0.65,
      tablet: 600.0,
      desktop: 700.0,
    );
  }
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Widget pour construire des layouts responsive
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.valueByDevice(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}
