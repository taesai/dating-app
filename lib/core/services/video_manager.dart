import 'package:video_player/video_player.dart';

/// Gestionnaire GLOBAL pour assurer qu'une seule vidéo joue à la fois
class VideoManager {
  static final VideoManager _instance = VideoManager._internal();
  factory VideoManager() => _instance;
  VideoManager._internal();

  VideoPlayerController? _currentlyPlayingController;

  /// Enregistrer un controller comme celui qui joue actuellement
  /// Arrête automatiquement tous les autres
  void setCurrentlyPlaying(VideoPlayerController controller) {
    if (_currentlyPlayingController == controller) {
      return; // Déjà le controller actif
    }

    // Arrêter le controller précédent
    if (_currentlyPlayingController != null) {
      try {
        _currentlyPlayingController!.pause();
        _currentlyPlayingController!.setVolume(0.0);
        print('🛑 VideoManager: Arrêt du controller précédent');
      } catch (e) {
        print('⚠️ Erreur arrêt controller précédent: $e');
      }
    }

    _currentlyPlayingController = controller;
    print('✅ VideoManager: Nouveau controller actif enregistré');
  }

  /// Arrêter le controller actuellement en lecture
  void stopCurrent() {
    if (_currentlyPlayingController != null) {
      try {
        _currentlyPlayingController!.pause();
        _currentlyPlayingController!.setVolume(0.0);
        print('🛑 VideoManager: Controller actuel arrêté');
      } catch (e) {
        print('⚠️ Erreur arrêt controller actuel: $e');
      }
      _currentlyPlayingController = null;
    }
  }

  /// Retirer un controller du tracking (lors du dispose)
  void unregisterController(VideoPlayerController controller) {
    if (_currentlyPlayingController == controller) {
      _currentlyPlayingController = null;
      print('🗑️ VideoManager: Controller actif supprimé du tracking');
    }
  }
}
