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

  static void stop(GlobalKey<State<StatefulWidget>> key) {
    final state = key.currentState;
    if (state is _WebVideoPlayerState) {
      state.stop();
    }
  }

  // Méthode GLOBALE pour arrêter TOUTES les vidéos HTML (Hot Reload)
  static void killAllVideos() {
    try {
      final allVideos = html.document.querySelectorAll('video');
      for (final video in allVideos) {
        if (video is html.VideoElement) {
          video.pause();
          video.muted = true;
          video.volume = 0.0;
          video.currentTime = 0;
          video.removeAttribute('src');
          video.load();
        }
      }
      print('💀 killAllVideos: ${allVideos.length} vidéos HTML complètement arrêtées');
    } catch (e) {
      print('⚠️ Erreur killAllVideos: $e');
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
    // Ne PAS appeler killAllVideos() ici - cela tue les autres players qui se créent en parallèle!
    _initializeVideoElement();
  }

  void _initializeVideoElement() {
    try {
      _viewType = 'video-${widget.videoUrl.hashCode}-${DateTime.now().microsecondsSinceEpoch}';

      _videoElement = html.VideoElement()
        ..src = widget.videoUrl
        ..autoplay = false  // DÉSACTIVER autoplay pour éviter chevauchement audio
        ..loop = widget.loop
        ..muted = true  // TOUJOURS muted au départ
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.backgroundColor = 'black'
        ..setAttribute('playsinline', 'true')
        ..setAttribute('webkit-playsinline', 'true')
        ..setAttribute('muted', 'true')  // Muted par défaut
        ..setAttribute('preload', 'auto'); // Préchargement du fichier seulement

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

      // DIAGNOSTIQUE: Compter combien de vidéos existent maintenant
      final totalVideos = html.document.querySelectorAll('video').length;
      print('✅ WebVideoPlayer enregistré: $_viewType (TOTAL vidéos dans DOM: $totalVideos)');
    } catch (e) {
      print('❌ Erreur WebVideoPlayer init: $e');
    }
  }

  @override
  void dispose() {
    try {
      // CRUCIAL: Arrêter complètement l'audio AVANT de disposer
      _videoElement?.pause();
      _videoElement?.muted = true;
      _videoElement?.volume = 0.0;
      _videoElement?.currentTime = 0;
      _videoElement?.removeAttribute('src');
      _videoElement?.load();
      _videoElement?.remove();
      _videoElement = null;
      print('🗑️ WebVideoPlayer dispose: vidéo complètement arrêtée et supprimée');
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
      final clampedVolume = volume.clamp(0.0, 1.0);
      final shouldMute = clampedVolume == 0.0;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      if (shouldMute) {
        // Volume = 0: ARRÊTER complètement la vidéo pour éviter chevauchement
        _videoElement?.pause();
        _videoElement?.muted = true;
        _videoElement?.volume = 0.0;
        _videoElement?.setAttribute('muted', 'true');

        final myUrl = _videoElement?.src ?? 'unknown';
        final shortUrl = myUrl.length > 60 ? '...${myUrl.substring(myUrl.length - 60)}' : myUrl;
        print('🔇 [$timestamp] Video STOPPED: $shortUrl');
      } else {
        // DIAGNOSTIQUE AVANT: Lister TOUTES les vidéos et leur état
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔍 [$timestamp] AVANT play() - État du DOM:');
        final allVideosBefore = html.document.querySelectorAll('video');
        for (int i = 0; i < allVideosBefore.length; i++) {
          final v = allVideosBefore[i];
          if (v is html.VideoElement) {
            final url = v.src.length > 60 ? '...${v.src.substring(v.src.length - 60)}' : v.src;
            final isMe = v == _videoElement ? '👈 MOI' : '';
            final playing = v.paused ? '⏸️ PAUSED' : '▶️ PLAYING';
            print('  Video $i: $playing $url $isMe');
          }
        }

        // Volume > 0: AVANT de démarrer, arrêter TOUTES les autres vidéos du DOM
        final allVideos = html.document.querySelectorAll('video');
        int stoppedBefore = 0;
        for (final video in allVideos) {
          if (video is html.VideoElement && video != _videoElement) {
            if (!video.paused) {
              stoppedBefore++;
            }
            video.pause();
            video.muted = true;
            video.volume = 0.0;
          }
        }
        print('🛑 Arrêt de $stoppedBefore vidéos AVANT play()');

        // Maintenant démarrer CETTE vidéo uniquement
        _videoElement?.muted = false;
        _videoElement?.volume = clampedVolume;
        _videoElement?.removeAttribute('muted');

        // Forcer le play() SEULEMENT si la vidéo n'est pas déjà en train de jouer
        try {
          final isPaused = _videoElement?.paused ?? true;
          if (isPaused) {
            final myUrl = _videoElement?.src ?? 'unknown';
            final shortUrl = myUrl.length > 60 ? '...${myUrl.substring(myUrl.length - 60)}' : myUrl;
            print('▶️ [$timestamp] APPEL play() sur: $shortUrl');

            // Démarrer CETTE vidéo
            _videoElement?.play();

            // Attendre 50ms pour que les vidéos soient dans le DOM, puis arrêter les autres
            Future.delayed(Duration(milliseconds: 50), () {
              try {
                final allVideosAfter = html.document.querySelectorAll('video');
                int stoppedAfter = 0;
                for (final v in allVideosAfter) {
                  if (v is html.VideoElement && v != _videoElement && !v.paused) {
                    v.pause();
                    v.muted = true;
                    v.volume = 0.0;
                    stoppedAfter++;
                  }
                }

                // DIAGNOSTIQUE APRÈS: Lister toutes les vidéos qui jouent MAINTENANT
                print('🔍 [${DateTime.now().millisecondsSinceEpoch}] 50ms APRÈS play() - Vidéos en lecture:');
                int playing = 0;
                for (int i = 0; i < allVideosAfter.length; i++) {
                  final v = allVideosAfter[i];
                  if (v is html.VideoElement && !v.paused) {
                    playing++;
                    final url = v.src.length > 60 ? '...${v.src.substring(v.src.length - 60)}' : v.src;
                    final isMe = v == _videoElement ? '👈 MOI' : '❌ AUTRE';
                    print('  ▶️ Video $i en lecture: $url $isMe');
                  }
                }
                print('📊 TOTAL: $playing vidéo(s) en lecture sur ${allVideosAfter.length} (arrêté: $stoppedAfter)');
                print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
              } catch (e) {
                print('⚠️ Erreur vérification après play: $e');
              }
            });
          } else {
            print('⏭️ [$timestamp] Vidéo déjà en lecture, volume mis à jour à $clampedVolume');
          }
        } catch (e) {
          print('⚠️ Play après unmute échoué: $e');
        }
      }

      print('🔊 setVolume: $clampedVolume, muted: $shouldMute');
    } catch (e) {
      print('⚠️ Erreur setVolume: $e');
    }
  }

  void stop() {
    try {
      _videoElement?.pause();
      _videoElement?.currentTime = 0;
      _videoElement?.load();
    } catch (e) {
      print('⚠️ Erreur stop: $e');
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
