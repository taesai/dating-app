import 'package:flutter/material.dart';

/// Indicateur de frappe animé (typing indicator)
class TypingIndicator extends StatefulWidget {
  final String userName;
  final Color? dotColor;

  const TypingIndicator({
    super.key,
    required this.userName,
    this.dotColor,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final dotColor = widget.dotColor ??
        (isDark ? Colors.grey[400] : Colors.grey[600]);

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.userName} écrit',
            style: TextStyle(
              fontSize: 12,
              color: dotColor,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 8),
          _AnimatedDot(
            controller: _controller,
            delay: 0.0,
            color: dotColor!,
          ),
          const SizedBox(width: 4),
          _AnimatedDot(
            controller: _controller,
            delay: 0.2,
            color: dotColor,
          ),
          const SizedBox(width: 4),
          _AnimatedDot(
            controller: _controller,
            delay: 0.4,
            color: dotColor,
          ),
        ],
      ),
    );
  }
}

/// Point animé pour l'indicateur de frappe
class _AnimatedDot extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Color color;

  const _AnimatedDot({
    required this.controller,
    required this.delay,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay,
          delay + 0.3,
          curve: Curves.easeInOut,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -6 * animation.value),
          child: Opacity(
            opacity: 0.4 + (0.6 * animation.value),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget simplifié pour afficher uniquement les 3 points animés
class SimpleTypingIndicator extends StatefulWidget {
  final Color? dotColor;
  final double size;

  const SimpleTypingIndicator({
    super.key,
    this.dotColor,
    this.size = 8.0,
  });

  @override
  State<SimpleTypingIndicator> createState() => _SimpleTypingIndicatorState();
}

class _SimpleTypingIndicatorState extends State<SimpleTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = widget.dotColor ??
        (isDark ? Colors.grey[400] : Colors.grey[600])!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnimatedDot(
          controller: _controller,
          delay: 0.0,
          color: dotColor,
        ),
        SizedBox(width: widget.size * 0.5),
        _AnimatedDot(
          controller: _controller,
          delay: 0.2,
          color: dotColor,
        ),
        SizedBox(width: widget.size * 0.5),
        _AnimatedDot(
          controller: _controller,
          delay: 0.4,
          color: dotColor,
        ),
      ],
    );
  }
}
