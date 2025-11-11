import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:html' as html;

/// Widget qui affiche une bannière quand la connexion internet est perdue
class OfflineIndicatorWidget extends StatefulWidget {
  const OfflineIndicatorWidget({super.key});

  @override
  State<OfflineIndicatorWidget> createState() => _OfflineIndicatorWidgetState();
}

class _OfflineIndicatorWidgetState extends State<OfflineIndicatorWidget> with SingleTickerProviderStateMixin {
  bool _isOnline = true;
  StreamSubscription<html.Event>? _onlineSubscription;
  StreamSubscription<html.Event>? _offlineSubscription;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _checkInitialStatus();
    _listenToConnectivity();
  }

  void _checkInitialStatus() {
    _isOnline = html.window.navigator.onLine ?? true;
  }

  void _listenToConnectivity() {
    _onlineSubscription = html.window.onOnline.listen((event) {
      if (mounted) {
        setState(() {
          _isOnline = true;
        });
        _animationController.reverse();
      }
    });

    _offlineSubscription = html.window.onOffline.listen((event) {
      if (mounted) {
        setState(() {
          _isOnline = false;
        });
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _onlineSubscription?.cancel();
    _offlineSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        elevation: 4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.shade700,
                Colors.red.shade500,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Connexion internet perdue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
