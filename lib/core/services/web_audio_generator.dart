import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:math' as math;
import 'dart:typed_data';

/// Générateur de sons synthétiques pour le web
class WebAudioGenerator {
  static final WebAudioGenerator _instance = WebAudioGenerator._internal();
  factory WebAudioGenerator() => _instance;
  WebAudioGenerator._internal();

  js.JsObject? _audioContext;

  js.JsObject get audioContext {
    if (_audioContext == null) {
      final audioContextConstructor = js.context['AudioContext'] ?? js.context['webkitAudioContext'];
      _audioContext = js.JsObject(audioContextConstructor as js.JsFunction);
    }
    return _audioContext!;
  }

  /// Jouer une fréquence pendant une durée
  Future<void> playTone({
    required double frequency,
    required double duration,
    double volume = 0.3,
    String type = 'sine', // 'sine', 'square', 'triangle', 'sawtooth'
  }) async {
    try {
      final context = audioContext;
      final oscillator = context.callMethod('createOscillator');
      final gainNode = context.callMethod('createGain');

      oscillator['type'] = type;
      oscillator['frequency']['value'] = frequency;

      gainNode['gain']['value'] = volume;

      oscillator.callMethod('connect', [gainNode]);
      gainNode.callMethod('connect', [context['destination']]);

      oscillator.callMethod('start', [0]);
      oscillator.callMethod('stop', [context['currentTime'] + duration]);
    } catch (e) {
      print('Erreur lecture son: $e');
    }
  }

  /// Jouer plusieurs tons en séquence
  Future<void> playSequence(List<Map<String, dynamic>> notes) async {
    try {
      final context = audioContext;
      double startTime = context['currentTime'];

      for (final note in notes) {
        final oscillator = context.callMethod('createOscillator');
        final gainNode = context.callMethod('createGain');

        oscillator['type'] = note['type'] ?? 'sine';
        oscillator['frequency']['value'] = note['frequency'];

        gainNode['gain']['value'] = note['volume'] ?? 0.3;

        oscillator.callMethod('connect', [gainNode]);
        gainNode.callMethod('connect', [context['destination']]);

        oscillator.callMethod('start', [startTime]);
        oscillator.callMethod('stop', [startTime + note['duration']]);

        startTime += note['duration'] as double;
      }
    } catch (e) {
      print('Erreur lecture séquence: $e');
    }
  }

  /// Son de swipe right (like) - montant joyeux
  Future<void> playSwipeRight({double volume = 0.3}) async {
    await playSequence([
      {'frequency': 523.25, 'duration': 0.1, 'volume': volume, 'type': 'sine'}, // C5
      {'frequency': 659.25, 'duration': 0.1, 'volume': volume, 'type': 'sine'}, // E5
      {'frequency': 783.99, 'duration': 0.15, 'volume': volume, 'type': 'sine'}, // G5
    ]);
  }

  /// Son de swipe left (pass) - descendant court
  Future<void> playSwipeLeft({double volume = 0.3}) async {
    await playSequence([
      {'frequency': 392.00, 'duration': 0.08, 'volume': volume, 'type': 'sine'}, // G4
      {'frequency': 329.63, 'duration': 0.08, 'volume': volume, 'type': 'sine'}, // E4
      {'frequency': 261.63, 'duration': 0.1, 'volume': volume, 'type': 'sine'}, // C4
    ]);
  }

  /// Son de match - célébration !
  Future<void> playMatch({double volume = 0.4}) async {
    await playSequence([
      {'frequency': 523.25, 'duration': 0.1, 'volume': volume, 'type': 'sine'}, // C5
      {'frequency': 659.25, 'duration': 0.1, 'volume': volume, 'type': 'sine'}, // E5
      {'frequency': 783.99, 'duration': 0.1, 'volume': volume, 'type': 'sine'}, // G5
      {'frequency': 1046.50, 'duration': 0.2, 'volume': volume, 'type': 'sine'}, // C6
      {'frequency': 783.99, 'duration': 0.1, 'volume': volume, 'type': 'sine'}, // G5
      {'frequency': 1046.50, 'duration': 0.3, 'volume': volume, 'type': 'sine'}, // C6
    ]);
  }

  /// Son de super like - magique ✨
  Future<void> playSuperLike({double volume = 0.35}) async {
    await playSequence([
      {'frequency': 659.25, 'duration': 0.08, 'volume': volume, 'type': 'triangle'}, // E5
      {'frequency': 783.99, 'duration': 0.08, 'volume': volume, 'type': 'triangle'}, // G5
      {'frequency': 987.77, 'duration': 0.08, 'volume': volume, 'type': 'triangle'}, // B5
      {'frequency': 1174.66, 'duration': 0.12, 'volume': volume, 'type': 'triangle'}, // D6
      {'frequency': 1318.51, 'duration': 0.15, 'volume': volume, 'type': 'triangle'}, // E6
    ]);
  }

  /// Son de message envoyé - "pop"
  Future<void> playMessageSent({double volume = 0.25}) async {
    await playTone(
      frequency: 800,
      duration: 0.05,
      volume: volume,
      type: 'sine',
    );
  }

  /// Son de message reçu - "ding" doux
  Future<void> playMessageReceived({double volume = 0.3}) async {
    await playSequence([
      {'frequency': 800, 'duration': 0.08, 'volume': volume, 'type': 'sine'},
      {'frequency': 1000, 'duration': 0.12, 'volume': volume * 0.8, 'type': 'sine'},
    ]);
  }

  /// Son de notification
  Future<void> playNotification({double volume = 0.3}) async {
    await playSequence([
      {'frequency': 880, 'duration': 0.1, 'volume': volume, 'type': 'sine'},
      {'frequency': 1108.73, 'duration': 0.15, 'volume': volume, 'type': 'sine'},
    ]);
  }

  /// Son de tap/clic léger
  Future<void> playTap({double volume = 0.2}) async {
    await playTone(
      frequency: 1000,
      duration: 0.03,
      volume: volume,
      type: 'sine',
    );
  }

  /// Son de succès - affirmatif
  Future<void> playSuccess({double volume = 0.3}) async {
    await playSequence([
      {'frequency': 523.25, 'duration': 0.08, 'volume': volume, 'type': 'sine'}, // C5
      {'frequency': 659.25, 'duration': 0.08, 'volume': volume, 'type': 'sine'}, // E5
      {'frequency': 783.99, 'duration': 0.15, 'volume': volume, 'type': 'sine'}, // G5
    ]);
  }

  /// Son d'erreur - descendant
  Future<void> playError({double volume = 0.3}) async {
    await playSequence([
      {'frequency': 400, 'duration': 0.1, 'volume': volume, 'type': 'square'},
      {'frequency': 300, 'duration': 0.1, 'volume': volume, 'type': 'square'},
      {'frequency': 200, 'duration': 0.15, 'volume': volume, 'type': 'square'},
    ]);
  }

  /// Son de whoosh (transition)
  Future<void> playWhoosh({double volume = 0.25}) async {
    try {
      final context = audioContext;
      final oscillator = context.callMethod('createOscillator');
      final gainNode = context.callMethod('createGain');

      oscillator['type'] = 'sawtooth';
      oscillator['frequency']['value'] = 100;

      // Fade in puis fade out
      final now = context['currentTime'];
      final gain = gainNode['gain'];
      gain.callMethod('setValueAtTime', [0, now]);
      gain.callMethod('linearRampToValueAtTime', [volume, now + 0.05]);
      gain.callMethod('linearRampToValueAtTime', [0, now + 0.2]);

      // Montée de fréquence
      final freq = oscillator['frequency'];
      freq.callMethod('setValueAtTime', [100, now]);
      freq.callMethod('exponentialRampToValueAtTime', [800, now + 0.2]);

      oscillator.callMethod('connect', [gainNode]);
      gainNode.callMethod('connect', [context['destination']]);

      oscillator.callMethod('start', [now]);
      oscillator.callMethod('stop', [now + 0.2]);
    } catch (e) {
      print('Erreur whoosh: $e');
    }
  }

  /// Son de vibration/haptic feedback simulé
  Future<void> playVibration({double volume = 0.2}) async {
    await playTone(
      frequency: 150,
      duration: 0.05,
      volume: volume,
      type: 'square',
    );
  }

  /// Nettoyer les ressources
  void dispose() {
    _audioContext?.callMethod('close');
  }
}
