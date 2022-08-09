library metaballs;
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'metaballs_shader_sprv.dart';

class _MetaBallComputedState {
  final double x;
  final double y;
  final double r;

  _MetaBallComputedState({
    required this.x,
    required this.y,
    required this.r,
  });
}

class _MetaBall {
  late double _x;
  late double _y;
  late double _vx;
  late double _vy;
  late double _r;

  _MetaBall() {
    final random = Random();
    _x = random.nextDouble();
    _y = random.nextDouble();
    _vx = (random.nextDouble() - 0.5) * 2;
    _vy = (random.nextDouble() - 0.5) * 2;
    _r = random.nextDouble();
  }

  _MetaBallComputedState update({
    required double minRadius,
    required double maxRadius,
    required Size canvasSize,
    required double frameTime,
    required double speedMultiplier
  }) {
    assert(maxRadius >= minRadius);
    
    // update the meta ball position
    final speed = frameTime*speedMultiplier;
    _x+=(_vx / canvasSize.aspectRatio)*0.1*speed;
    _y+=_vy*0.1*speed;
    final m = speed*400;
    if(_x < 0) {
      _vx+=m*-_x;
    } else if (_x > 1) {
      _vx-=m*(_x-1);
    }
    if(_y < 0) {
      _vy+=m*-_y;
    } else if (_y > 1) {
      _vy-=m*(_y-1);
    }

    // transform the local state relative to canvas
    final scale = sqrt(canvasSize.width * canvasSize.height) / 1000;
    final r = (((maxRadius - minRadius) * _r) + minRadius) * scale;
    final d = r * 2;
    final x = ((canvasSize.width - d) * _x) + r;
    final y = ((canvasSize.height - d) * _y) + r;
    return _MetaBallComputedState(x: x, y: y, r: r);
  }
}

class MetaBalls extends StatefulWidget {
  final Color color1;
  final Color color2;
  final double glowRadius;
  final double glowIntensity;
  final double minBallRadius;
  final double maxBallRadius;
  final double speedMultiplier;
  final Alignment gradientAlignment;
  final Widget? child;

  const MetaBalls({
    Key? key,
    required this.color1,
    required this.color2,
    this.speedMultiplier = 1,
    this.minBallRadius = 15,
    this.maxBallRadius = 40,
    this.glowRadius = 0.7,
    this.glowIntensity = 0.6,
    this.gradientAlignment = Alignment.bottomRight,
    this.child
  }) : super(key: key);

  @override
  State<MetaBalls> createState() => _MetaBallsState();
}

class _MetaBallsState extends State<MetaBalls> with TickerProviderStateMixin {
  late List<_MetaBall> _metaBalls;
  late AnimationController _controller;
  late Future<FragmentProgram> _fragmentProgramFuture;
  double _lastFrame = 0;

  @override
  void initState() {
    _controller = AnimationController.unbounded(
      duration: const Duration(days: 365), vsync: this
    )..animateTo(const Duration(days: 365).inSeconds.toDouble());

    _fragmentProgramFuture = metaballsShaderFragmentProgram().catchError((error) {
      // ignore: avoid_print
      print('shader error: $error');
    });

    _metaBalls = List.generate(40, (_) => _MetaBall());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final futureBuilder = FutureBuilder<FragmentProgram>(
      future: _fragmentProgramFuture,
      builder: (context, snapshot) {
        if(snapshot.hasData) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final currentFrame = _controller.value;
                  final frameTime = currentFrame - _lastFrame;
                  _lastFrame = currentFrame;

                  final computed = _metaBalls.map((metaBall) => metaBall.update(
                    canvasSize: size,
                    frameTime: frameTime,
                    maxRadius: widget.maxBallRadius,
                    minRadius: widget.minBallRadius,
                    speedMultiplier: widget.speedMultiplier
                  )).toList();

                  return SizedBox.expand(
                    child: CustomPaint(
                      painter: _MetaBallPainter(
                        color1: widget.color1,
                        color2: widget.color2,
                        fragmentProgram: snapshot.data!,
                        metaBalls: computed,
                        glowRadius: widget.glowRadius,
                        glowIntensity: widget.glowIntensity,
                        size: size,
                        gradientAlignment: widget.gradientAlignment
                      ),
                    ),
                  );
                },
              );
            }
          );
        } else {
          return Container();
        }
      }
    );
    if(widget.child != null) {
      return Stack(
        children: [
          futureBuilder,
          widget.child!,
        ],
      );
    } else {
      return futureBuilder;
    }
  }
}

/// Customer painter that makes use of the shader
class _MetaBallPainter extends CustomPainter {
  _MetaBallPainter({
    required this.fragmentProgram,
    required this.color1,
    required this.color2,
    required this.glowRadius,
    required this.glowIntensity,
    required this.size,
    required this.metaBalls, 
    required this.gradientAlignment
  });

  final FragmentProgram fragmentProgram;
  final Color color1;
  final Color color2;
  final Size size;
  final List<_MetaBallComputedState> metaBalls;
  final double glowRadius;
  final double glowIntensity;
  final Alignment gradientAlignment;

  @override
  void paint(Canvas canvas, Size size) {
    final List<double> doubles = [
      sqrt(size.width * size.width + size.height * size.height),
      color1.red / 255.0,
      color1.green / 255.0,
      color1.blue / 255.0,
      color2.red / 255.0,
      color2.green / 255.0,
      color2.blue / 255.0,
      size.width,
      size.height,
      min(max(1-glowRadius, 0), 1),
      min(max(glowIntensity, 0), 1),
      size.width * ((gradientAlignment.x + 1) / 2),
      size.height * ((gradientAlignment.y + 1) / 2)
    ];

    for(final _MetaBallComputedState metaBall in metaBalls) {
      doubles.add(metaBall.x);
      doubles.add(metaBall.y);
      doubles.add(metaBall.r);
    }

    final paint = Paint()
      ..shader = fragmentProgram.shader(
        floatUniforms: Float32List.fromList(doubles),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}