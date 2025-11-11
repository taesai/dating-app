import 'package:flutter/material.dart';
import 'package:clay_containers/clay_containers.dart';
import '../../core/utils/responsive_helper.dart';

/// Bouton neumorphic pour ajouter des vidéos utilisant clay_containers
class ClayVideoButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String? label;
  final bool showLabel;
  final double? size;
  final Color? baseColor;
  final Color? iconColor;

  const ClayVideoButton({
    super.key,
    required this.onTap,
    this.icon = Icons.videocam,
    this.label,
    this.showLabel = true,
    this.size,
    this.baseColor,
    this.iconColor,
  });

  @override
  State<ClayVideoButton> createState() => _ClayVideoButtonState();
}

class _ClayVideoButtonState extends State<ClayVideoButton> {
  bool _isPressed = false;

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

    final baseColor = widget.baseColor ?? const Color(0xFFE0E5EC);
    final iconColor = widget.iconColor ?? Colors.purple;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton principal avec effet clay
          ClayContainer(
            width: buttonSize,
            height: buttonSize,
            depth: _isPressed ? 20 : 40, // Profondeur réduite quand pressé
            spread: _isPressed ? 2 : 4,
            color: baseColor,
            borderRadius: 20, // Carré avec coins arrondis
            curveType: _isPressed ? CurveType.concave : CurveType.convex,
            child: Center(
              child: Icon(
                widget.icon,
                size: iconSize,
                color: iconColor,
              ),
            ),
          ),

          // Label optionnel
          if (widget.showLabel && widget.label != null) ...[
            SizedBox(
              height: ResponsiveHelper.valueByDevice(
                context: context,
                mobile: 8.0,
                tablet: 10.0,
                desktop: 12.0,
              ),
            ),
            Text(
              widget.label!,
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
    );
  }
}
