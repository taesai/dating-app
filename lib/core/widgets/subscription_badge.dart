import 'package:flutter/material.dart';

class SubscriptionBadge extends StatelessWidget {
  final String plan;

  const SubscriptionBadge({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color textColor;
    String displayText;
    IconData icon;

    switch (plan) {
      case 'gold':
        badgeColor = Colors.amber;
        textColor = Colors.white;
        displayText = 'GOLD';
        icon = Icons.workspace_premium;
        break;
      case 'silver':
        badgeColor = Colors.purple;
        textColor = Colors.white;
        displayText = 'SILVER';
        icon = Icons.star;
        break;
      default:
        badgeColor = Colors.blue;
        textColor = Colors.white;
        displayText = 'FREE';
        icon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
