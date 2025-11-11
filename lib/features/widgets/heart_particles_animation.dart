import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animation de particules de cœurs qui montent et disparaissent
class HeartParticlesAnimation extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color particleColor;
  final int particleCount;

  const HeartParticlesAnimation({
    super.key,
    required this.child,
    this.isActive = false,
    this.particleColor = Colors.pink,
    this.particleCount = 20,
  });

  @override
  State<HeartParticlesAnimation> createState() => _HeartParticlesAnimationState();
}

class _HeartParticlesAnimationState extends State<HeartParticlesAnimation> with TickerProviderStateMixin {
  List<AnimationController> _controllers = [];
  List<HeartParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initializeParticles();
  }

  void _initializeParticles() {
    _controllers.clear();
    _particles.clear();

    for (int i = 0; i < widget.particleCount; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1500 + _random.nextInt(1000)),
      );

      _controllers.add(controller);
      _particles.add(HeartParticle(
        xOffset: _random.nextDouble() * 2 - 1, // -1 à 1
        delay: _random.nextInt(500),
        size: 15.0 + _random.nextDouble() * 15, // 15-30
        rotation: _random.nextDouble() * math.pi * 2,
      ));
    }
  }

  @override
  void didUpdateWidget(HeartParticlesAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive && !oldWidget.isActive) {
      _startAnimation();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopAnimation();
    }
  }

  void _startAnimation() {
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: _particles[i].delay), () {
        if (mounted && widget.isActive) {
          _controllers[i].repeat();
        }
      });
    }
  }

  void _stopAnimation() {
    for (var controller in _controllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isActive)
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: List.generate(_particles.length, (index) {
                  return AnimatedBuilder(
                    animation: _controllers[index],
                    builder: (context, child) {
                      return Positioned(
                        left: MediaQuery.of(context).size.width / 2 +
                              (_particles[index].xOffset * 100 * _controllers[index].value),
                        bottom: -20 + (MediaQuery.of(context).size.height * _controllers[index].value),
                        child: Opacity(
                          opacity: 1.0 - _controllers[index].value,
                          child: Transform.rotate(
                            angle: _particles[index].rotation * _controllers[index].value,
                            child: Icon(
                              Icons.favorite,
                              color: widget.particleColor,
                              size: _particles[index].size,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }
}

class HeartParticle {
  final double xOffset;
  final int delay;
  final double size;
  final double rotation;

  HeartParticle({
    required this.xOffset,
    required this.delay,
    required this.size,
    required this.rotation,
  });
}
