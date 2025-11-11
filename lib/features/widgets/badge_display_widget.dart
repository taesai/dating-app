import 'package:flutter/material.dart';
import '../../core/models/verification_badge.dart';

/// Widget pour afficher un badge de vérification
class BadgeDisplayWidget extends StatelessWidget {
  final VerificationBadge badge;
  final double size;
  final bool showLabel;
  final bool showTooltip;

  const BadgeDisplayWidget({
    super.key,
    required this.badge,
    this.size = 24,
    this.showLabel = false,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final badgeWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: badge.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: badge.color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        badge.icon,
        size: size * 0.6,
        color: Colors.white,
      ),
    );

    if (showLabel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badgeWidget,
          const SizedBox(width: 6),
          Text(
            badge.label,
            style: TextStyle(
              fontSize: size * 0.6,
              fontWeight: FontWeight.w600,
              color: badge.color,
            ),
          ),
        ],
      );
    }

    if (showTooltip) {
      return Tooltip(
        message: '${badge.label}\n${badge.description}',
        child: badgeWidget,
      );
    }

    return badgeWidget;
  }
}

/// Widget pour afficher plusieurs badges en ligne
class BadgeRowWidget extends StatelessWidget {
  final List<String>? badgeNames;
  final double size;
  final int maxBadges;
  final bool showLabels;

  const BadgeRowWidget({
    super.key,
    this.badgeNames,
    this.size = 20,
    this.maxBadges = 3,
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    final badges = BadgeHelper.getUserBadges(badgeNames);

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayBadges = badges.take(maxBadges).toList();
    final remainingCount = badges.length - displayBadges.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...displayBadges.map((badge) => BadgeDisplayWidget(
              badge: badge,
              size: size,
              showLabel: showLabels,
            )),
        if (remainingCount > 0)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '+$remainingCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget pour afficher tous les badges d'un utilisateur en grille
class BadgeGridWidget extends StatelessWidget {
  final List<String>? badgeNames;
  final double size;

  const BadgeGridWidget({
    super.key,
    this.badgeNames,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final badges = BadgeHelper.getUserBadges(badgeNames);

    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun badge pour le moment',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Continuez à utiliser l\'app pour débloquer des badges !',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _BadgeCard(badge: badge, size: size);
      },
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final VerificationBadge badge;
  final double size;

  const _BadgeCard({
    required this.badge,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: badge.color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: badge.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              badge.icon,
              size: size * 0.6,
              color: badge.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: badge.color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Badge animé avec shimmer effect
class AnimatedBadgeWidget extends StatefulWidget {
  final VerificationBadge badge;
  final double size;

  const AnimatedBadgeWidget({
    super.key,
    required this.badge,
    this.size = 80,
  });

  @override
  State<AnimatedBadgeWidget> createState() => _AnimatedBadgeWidgetState();
}

class _AnimatedBadgeWidgetState extends State<AnimatedBadgeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.badge.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.badge.color.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                widget.badge.icon,
                size: widget.size * 0.6,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
