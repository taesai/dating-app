import 'package:flutter/material.dart';
import '../../core/utils/responsive_helper.dart';

/// Widgets neumorphic pour un design moderne et élégant
///
/// Le design neumorphic crée une illusion de profondeur avec des ombres douces
/// qui donnent l'impression que les éléments sont extrudés ou enfoncés dans la surface.

/// Couleurs neumorphic par défaut
class NeumorphicColors {
  static const Color background = Color(0xFFE0E5EC);
  static const Color darkBackground = Color(0xFF2A2D3E); // Pour fond sombre
  static const Color darkShadow = Color(0xFFA3B1C6);
  static const Color lightShadow = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFFFF4458);
  static const Color secondary = Color(0xFF6C63FF);
  static const Color purple = Color(0xFF8B5CF6);
}

/// Types de relief neumorphic
enum NeumorphicStyle {
  flat,     // Bouton plat (défaut)
  convex,   // Bouton bombé
  concave,  // Bouton enfoncé
  emboss,   // Relief accentué
}

/// Bouton neumorphic responsive pour ajouter des vidéos
class NeumorphicVideoButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Color? iconColor;
  final NeumorphicStyle style;
  final bool showLabel;
  final double? size;

  const NeumorphicVideoButton({
    super.key,
    required this.onTap,
    this.icon = Icons.video_library,
    this.label = 'Ajouter une vidéo',
    this.backgroundColor,
    this.iconColor,
    this.style = NeumorphicStyle.flat,
    this.showLabel = true,
    this.size,
  });

  @override
  State<NeumorphicVideoButton> createState() => _NeumorphicVideoButtonState();
}

class _NeumorphicVideoButtonState extends State<NeumorphicVideoButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Taille responsive
    final buttonSize = widget.size ??
        ResponsiveHelper.getButtonSize(
          context,
          mobile: 70,
          tablet: 80,
          desktop: 90,
        );

    final iconSize = ResponsiveHelper.getIconSize(
      context,
      mobile: 32,
      tablet: 36,
      desktop: 40,
    );

    final fontSize = ResponsiveHelper.getFontSize(
      context,
      mobile: 14,
      tablet: 16,
      desktop: 18,
    );

    final bgColor = widget.backgroundColor ?? NeumorphicColors.background;
    final iColor = widget.iconColor ?? NeumorphicColors.primary;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton principal
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: _isPressed
                    ? _getInnerShadows()
                    : _getOuterShadows(widget.style),
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: iconSize,
                  color: iColor,
                ),
              ),
            ),

            // Label optionnel
            if (widget.showLabel) ...[
              SizedBox(height: ResponsiveHelper.valueByDevice(
                context: context,
                mobile: 8.0,
                tablet: 10.0,
                desktop: 12.0,
              )),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<BoxShadow> _getOuterShadows(NeumorphicStyle style) {
    switch (style) {
      case NeumorphicStyle.flat:
        return [
          BoxShadow(
            color: NeumorphicColors.darkShadow.withOpacity(0.5),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: NeumorphicColors.lightShadow,
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
        ];

      case NeumorphicStyle.convex:
        return [
          BoxShadow(
            color: NeumorphicColors.darkShadow.withOpacity(0.6),
            offset: const Offset(8, 8),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: NeumorphicColors.lightShadow,
            offset: const Offset(-8, -8),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ];

      case NeumorphicStyle.concave:
        return [
          BoxShadow(
            color: NeumorphicColors.lightShadow,
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: NeumorphicColors.darkShadow.withOpacity(0.5),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
        ];

      case NeumorphicStyle.emboss:
        return [
          BoxShadow(
            color: NeumorphicColors.darkShadow.withOpacity(0.7),
            offset: const Offset(10, 10),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: NeumorphicColors.lightShadow,
            offset: const Offset(-10, -10),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ];
    }
  }

  List<BoxShadow> _getInnerShadows() {
    return [
      BoxShadow(
        color: NeumorphicColors.darkShadow.withOpacity(0.4),
        offset: const Offset(3, 3),
        blurRadius: 6,
      ),
      BoxShadow(
        color: NeumorphicColors.lightShadow.withOpacity(0.9),
        offset: const Offset(-3, -3),
        blurRadius: 6,
      ),
    ];
  }
}

/// Bouton neumorphic générique personnalisable
class NeumorphicButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final NeumorphicStyle style;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const NeumorphicButton({
    super.key,
    required this.onTap,
    required this.child,
    this.width,
    this.height,
    this.backgroundColor,
    this.style = NeumorphicStyle.flat,
    this.borderRadius,
    this.padding,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? NeumorphicColors.background;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(15);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          height: widget.height,
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            boxShadow: _isPressed
                ? _getInnerShadows()
                : _getOuterShadows(widget.style),
          ),
          child: widget.child,
        ),
      ),
    );
  }

  List<BoxShadow> _getOuterShadows(NeumorphicStyle style) {
    switch (style) {
      case NeumorphicStyle.flat:
        return [
          BoxShadow(
            color: NeumorphicColors.darkShadow.withOpacity(0.5),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: NeumorphicColors.lightShadow,
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
        ];

      case NeumorphicStyle.convex:
        return [
          BoxShadow(
            color: NeumorphicColors.darkShadow.withOpacity(0.6),
            offset: const Offset(8, 8),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: NeumorphicColors.lightShadow,
            offset: const Offset(-8, -8),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ];

      case NeumorphicStyle.concave:
        return [
          BoxShadow(
            color: NeumorphicColors.lightShadow,
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: NeumorphicColors.darkShadow.withOpacity(0.5),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
        ];

      case NeumorphicStyle.emboss:
        return [
          BoxShadow(
            color: NeumorphicColors.darkShadow.withOpacity(0.7),
            offset: const Offset(10, 10),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: NeumorphicColors.lightShadow,
            offset: const Offset(-10, -10),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ];
    }
  }

  List<BoxShadow> _getInnerShadows() {
    return [
      BoxShadow(
        color: NeumorphicColors.darkShadow.withOpacity(0.4),
        offset: const Offset(3, 3),
        blurRadius: 6,
      ),
      BoxShadow(
        color: NeumorphicColors.lightShadow.withOpacity(0.9),
        offset: const Offset(-3, -3),
        blurRadius: 6,
      ),
    ];
  }
}

/// Container neumorphic pour créer des sections avec effet de profondeur
class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final NeumorphicStyle style;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.backgroundColor,
    this.style = NeumorphicStyle.flat,
    this.borderRadius,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? NeumorphicColors.background;
    final borderRadius = this.borderRadius ?? BorderRadius.circular(20);

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
        boxShadow: _getShadows(style),
      ),
      child: child,
    );
  }

  List<BoxShadow> _getShadows(NeumorphicStyle style) {
    switch (style) {
      case NeumorphicStyle.flat:
        return [
          BoxShadow(
            color: NeumorphicColors.darkShadow.withOpacity(0.5),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: NeumorphicColors.lightShadow,
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
        ];

      case NeumorphicStyle.convex:
        return [
          BoxShadow(
            color: NeumorphicColors.darkShadow.withOpacity(0.6),
            offset: const Offset(8, 8),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: NeumorphicColors.lightShadow,
            offset: const Offset(-8, -8),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ];

      case NeumorphicStyle.concave:
        return [
          BoxShadow(
            color: NeumorphicColors.lightShadow,
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: NeumorphicColors.darkShadow.withOpacity(0.5),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
        ];

      case NeumorphicStyle.emboss:
        return [
          BoxShadow(
            color: NeumorphicColors.darkShadow.withOpacity(0.7),
            offset: const Offset(10, 10),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: NeumorphicColors.lightShadow,
            offset: const Offset(-10, -10),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ];
    }
  }
}

/// Toggle switch neumorphic
class NeumorphicToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final double? width;
  final double? height;

  const NeumorphicToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.width,
    this.height,
  });

  @override
  State<NeumorphicToggle> createState() => _NeumorphicToggleState();
}

class _NeumorphicToggleState extends State<NeumorphicToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
      value: widget.value ? 1.0 : 0.0,
    );

    _positionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(NeumorphicToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width ?? 60.0;
    final height = widget.height ?? 30.0;
    final activeColor = widget.activeColor ?? NeumorphicColors.primary;
    final inactiveColor =
        widget.inactiveColor ?? NeumorphicColors.background;

    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedBuilder(
        animation: _positionAnimation,
        builder: (context, child) {
          final color = Color.lerp(
            inactiveColor,
            activeColor,
            _positionAnimation.value,
          )!;

          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: NeumorphicColors.background,
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: [
                BoxShadow(
                  color: NeumorphicColors.darkShadow.withOpacity(0.3),
                  offset: const Offset(3, 3),
                  blurRadius: 6,
                ),
                BoxShadow(
                  color: NeumorphicColors.lightShadow,
                  offset: const Offset(-3, -3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Align(
                alignment: Alignment.lerp(
                  Alignment.centerLeft,
                  Alignment.centerRight,
                  _positionAnimation.value,
                )!,
                child: Container(
                  width: height - 6,
                  height: height - 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
