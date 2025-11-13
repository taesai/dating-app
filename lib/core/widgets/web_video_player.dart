import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Lecteur vidéo optimisé pour Web utilisant l'élément HTML natif
/// Évite les problèmes de guarantee_channel.dart du video_player package
class WebVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool loop;
  final bool muted;
  final VoidCallback? onEnded;
  final VoidCallback? onReady;

  const WebVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.autoPlay = true,
    this.loop = true,
    this.muted = false,
    this.onEnded,
    this.onReady,
  }) : super(key: key);

  @override
  State<WebVideoPlayer> createState() => _WebVideoPlayerState();

  // Méthodes publiques pour contrôler la vidéo via GlobalKey
  static void play(GlobalKey<State<StatefulWidget>> key) {
    final state = key.currentState;
    if (state is _WebVideoPlayerState) {
      state.play();
    }
  }

  static void pause(GlobalKey<State<StatefulWidget>> key) {
    final state = key.currentState;
    if (state is _WebVideoPlayerState) {
      state.pause();
    }
  }

  static void setVolume(GlobalKey<State<StatefulWidget>> key, double volume) {
    final state = key.currentState;
    if (state is _WebVideoPlayerState) {
      state.setVolume(volume);
    }
  }
}

class _WebVideoPlayerState extends State<WebVideoPlayer> {
  html.VideoElement? _videoElement;
  String? _viewType;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoElement();
  }

  void _initializeVideoElement() {
    try {
      _viewType = 'video-${widget.videoUrl.hashCode}-${DateTime.now().microsecondsSinceEpoch}';

      _videoElement = html.VideoElement()
        ..src = widget.videoUrl
        ..autoplay = widget.autoPlay
        ..loop = widget.loop
        ..muted = widget.muted
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.backgroundColor = 'black'
        ..setAttribute('playsinline', 'true')
        ..setAttribute('webkit-playsinline', 'true')
        ..setAttribute('preload', 'auto'); // Préchargement agressif pour réduire le délai

      // Événements
      _videoElement?.onCanPlay.listen((_) {
        widget.onReady?.call();
      });

      _videoElement?.onEnded.listen((_) {
        widget.onEnded?.call();
      });

      // Enregistrer la vue pour Flutter Web
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType!,
        (int viewId) => _videoElement!,
      );

      _isRegistered = true;
      print('✅ WebVideoPlayer enregistré: $_viewType');
    } catch (e) {
      print('❌ Erreur WebVideoPlayer init: $e');
    }
  }

  @override
  void dispose() {
    try {
      _videoElement?.pause();
      _videoElement?.removeAttribute('src');
      _videoElement?.load();
      _videoElement?.remove();
      _videoElement = null;
    } catch (e) {
      print('⚠️ Erreur dispose WebVideoPlayer: $e');
    }
    super.dispose();
  }

  void play() {
    try {
      _videoElement?.play();
    } catch (e) {
      print('⚠️ Erreur play: $e');
    }
  }

  void pause() {
    try {
      _videoElement?.pause();
    } catch (e) {
      print('⚠️ Erreur pause: $e');
    }
  }

  void setVolume(double volume) {
    try {
      _videoElement?.volume = volume.clamp(0.0, 1.0);
    } catch (e) {
      print('⚠️ Erreur setVolume: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRegistered || _viewType == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return HtmlElementView(viewType: _viewType!);
  }
}

/// Widget de contrôle pour le lecteur vidéo
class WebVideoPlayerControls extends StatefulWidget {
  final GlobalKey<_WebVideoPlayerState> playerKey;

  const WebVideoPlayerControls({
    Key? key,
    required this.playerKey,
  }) : super(key: key);

  @override
  State<WebVideoPlayerControls> createState() => _WebVideoPlayerControlsState();
}

class _WebVideoPlayerControlsState extends State<WebVideoPlayerControls> {
  bool _isPlaying = true;

  void _togglePlayPause() {
    final player = widget.playerKey.currentState;
    if (player != null) {
      setState(() {
        _isPlaying = !_isPlaying;
      });
      if (_isPlaying) {
        player.play();
      } else {
        player.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: IconButton(
        icon: Icon(
          _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
          color: Colors.white,
          size: 48,
        ),
        onPressed: _togglePlayPause,
      ),
    );
  }
}
