import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Widget qui affiche une vidéo en arrière-plan en boucle
class BackgroundVideo extends StatefulWidget {
  final String videoAsset;
  final Widget? child;
  final bool muted;
  final BoxFit fit;
  final double opacity;

  const BackgroundVideo({
    super.key,
    required this.videoAsset,
    this.child,
    this.muted = true,
    this.fit = BoxFit.cover,
    this.opacity = 1.0,
  });

  @override
  State<BackgroundVideo> createState() => _BackgroundVideoState();
}

class _BackgroundVideoState extends State<BackgroundVideo> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset(widget.videoAsset);

    try {
      await _controller.initialize();
      _controller.setLooping(true);
      if (widget.muted) {
        _controller.setVolume(0);
      }
      _controller.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation de la vidéo: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isInitialized)
          Opacity(
            opacity: widget.opacity,
            child: FittedBox(
              fit: widget.fit,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          )
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}
