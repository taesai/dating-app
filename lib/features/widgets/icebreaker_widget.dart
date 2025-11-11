import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/models/icebreaker.dart';

/// Widget qui affiche des suggestions de brise-glace pour démarrer une conversation
class IcebreakerWidget extends StatefulWidget {
  final Function(String) onIcebreakerSelected;
  final String? category;

  const IcebreakerWidget({
    super.key,
    required this.onIcebreakerSelected,
    this.category,
  });

  @override
  State<IcebreakerWidget> createState() => _IcebreakerWidgetState();
}

class _IcebreakerWidgetState extends State<IcebreakerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final math.Random _random = math.Random();
  List<Icebreaker> _suggestions = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _loadSuggestions();
    _animationController.forward();
  }

  void _loadSuggestions() {
    if (widget.category != null) {
      _suggestions = IcebreakerList.getByCategory(widget.category!);
    } else {
      _suggestions = IcebreakerList.defaultIcebreakers;
    }
    _suggestions.shuffle(_random);
    _suggestions = _suggestions.take(5).toList();
  }

  void _nextSuggestion() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _suggestions.length;
    });
    _animationController.reset();
    _animationController.forward();
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'fun': return '🎉';
      case 'travel': return '✈️';
      case 'hobby': return '🎨';
      case 'food': return '🍕';
      case 'deep': return '💭';
      case 'compliment': return '💫';
      default: return '💬';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentIcebreaker = _suggestions[_currentIndex];
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Brise-glace suggéré',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _nextSuggestion,
                  tooltip: 'Autre suggestion',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Icebreaker content
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Category icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getCategoryIcon(currentIcebreaker.category),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Text
                    Expanded(
                      child: Text(
                        currentIcebreaker.text,
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onIcebreakerSelected(currentIcebreaker.text);
                },
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Utiliser ce message'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
