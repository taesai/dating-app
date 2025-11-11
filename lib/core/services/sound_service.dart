import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'web_audio_generator.dart';

/// Service pour gérer les effets sonores de l'application
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final WebAudioGenerator _audioGenerator = WebAudioGenerator();
  bool _soundsEnabled = true;
  double _volume = 0.5;

  // Clés de stockage
  static const String _soundsEnabledKey = 'sounds_enabled';
  static const String _volumeKey = 'sound_volume';

  /// Initialiser le service
  Future<void> init() async {
    await _loadPreferences();
  }

  /// Charger les préférences
  Future<void> _loadPreferences() async {
    try {
      final soundsStored = html.window.localStorage[_soundsEnabledKey];
      if (soundsStored != null) {
        _soundsEnabled = soundsStored == 'true';
      }

      final volumeStored = html.window.localStorage[_volumeKey];
      if (volumeStored != null) {
        _volume = double.parse(volumeStored);
      }
    } catch (e) {
      if (kDebugMode) print('Erreur chargement préférences son: $e');
    }
  }

  /// Sauvegarder les préférences
  Future<void> _savePreferences() async {
    try {
      html.window.localStorage[_soundsEnabledKey] = _soundsEnabled.toString();
      html.window.localStorage[_volumeKey] = _volume.toString();
    } catch (e) {
      if (kDebugMode) print('Erreur sauvegarde préférences son: $e');
    }
  }

  /// Activer/désactiver les sons
  Future<void> setSoundsEnabled(bool enabled) async {
    _soundsEnabled = enabled;
    await _savePreferences();
  }

  /// Définir le volume (0.0 à 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _savePreferences();
  }

  bool get soundsEnabled => _soundsEnabled;
  double get volume => _volume;

  // === SONS DE L'APPLICATION ===

  /// Son de swipe à droite (like)
  Future<void> playSwipeRight() async {
    if (!_soundsEnabled) return;
    await _audioGenerator.playSwipeRight(volume: _volume);
  }

  /// Son de swipe à gauche (pass)
  Future<void> playSwipeLeft() async {
    if (!_soundsEnabled) return;
    await _audioGenerator.playSwipeLeft(volume: _volume);
  }

  /// Son de match
  Future<void> playMatch() async {
    if (!_soundsEnabled) return;
    await _audioGenerator.playMatch(volume: _volume);
  }

  /// Son de super like
  Future<void> playSuperLike() async {
    if (!_soundsEnabled) return;
    await _audioGenerator.playSuperLike(volume: _volume);
  }

  /// Son de message envoyé
  Future<void> playMessageSent() async {
    if (!_soundsEnabled) return;
    await _audioGenerator.playMessageSent(volume: _volume);
  }

  /// Son de message reçu
  Future<void> playMessageReceived() async {
    if (!_soundsEnabled) return;
    await _audioGenerator.playMessageReceived(volume: _volume);
  }

  /// Son de notification
  Future<void> playNotification() async {
    if (!_soundsEnabled) return;
    await _audioGenerator.playNotification(volume: _volume);
  }

  /// Son de clic/tap
  Future<void> playTap() async {
    if (!_soundsEnabled) return;
    await _audioGenerator.playTap(volume: _volume);
  }

  /// Son de succès
  Future<void> playSuccess() async {
    if (!_soundsEnabled) return;
    await _audioGenerator.playSuccess(volume: _volume);
  }

  /// Son d'erreur
  Future<void> playError() async {
    if (!_soundsEnabled) return;
    await _audioGenerator.playError(volume: _volume);
  }

  /// Son de "whoosh" (transition)
  Future<void> playWhoosh() async {
    if (!_soundsEnabled) return;
    await _audioGenerator.playWhoosh(volume: _volume);
  }

  /// Son de vibration/haptic
  Future<void> playVibration() async {
    if (!_soundsEnabled) return;
    await _audioGenerator.playVibration(volume: _volume);
  }

  /// Nettoyer les ressources
  void dispose() {
    _audioGenerator.dispose();
  }
}

/// Widget helper pour ajouter du son à un bouton
class SoundButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final String? soundType;

  const SoundButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.soundType,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Jouer le son approprié
        final soundService = SoundService();
        switch (soundType) {
          case 'tap':
            soundService.playTap();
            break;
          case 'success':
            soundService.playSuccess();
            break;
          case 'error':
            soundService.playError();
            break;
          default:
            soundService.playTap();
        }
        onPressed();
      },
      child: child,
    );
  }
}

/// Mixin pour ajouter facilement des sons aux widgets
mixin SoundMixin {
  final SoundService _soundService = SoundService();

  Future<void> playSwipeRight() => _soundService.playSwipeRight();
  Future<void> playSwipeLeft() => _soundService.playSwipeLeft();
  Future<void> playMatch() => _soundService.playMatch();
  Future<void> playSuperLike() => _soundService.playSuperLike();
  Future<void> playMessageSent() => _soundService.playMessageSent();
  Future<void> playMessageReceived() => _soundService.playMessageReceived();
  Future<void> playNotification() => _soundService.playNotification();
  Future<void> playTap() => _soundService.playTap();
  Future<void> playSuccess() => _soundService.playSuccess();
  Future<void> playError() => _soundService.playError();
  Future<void> playWhoosh() => _soundService.playWhoosh();
  Future<void> playVibration() => _soundService.playVibration();
}
