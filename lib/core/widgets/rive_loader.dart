import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient;

/// Widget de chargement réutilisable avec animation Rive
class RiveLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const RiveLoader({
    super.key,
    this.size = 50.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: RiveAnimation.asset(
        'assets/animations/progress-bar.riv',
        fit: BoxFit.contain,
        onInit: (artboard) {
          // Animation chargée avec succès
        },
      ),
    );
  }
}
