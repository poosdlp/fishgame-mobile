import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class FishData {
  final double yFactor;
  final double speed;
  final double size;
  final bool leftToRight;
  final double startOffset;

  const FishData({
    required this.yFactor,
    required this.speed,
    required this.size,
    required this.leftToRight,
    required this.startOffset,
  });
}

const List<FishData> defaultFish = [
  FishData(
    yFactor: 0.42,
    speed: 0.05,
    size: 26,
    leftToRight: true,
    startOffset: 0.00,
  ),
  FishData(
    yFactor: 0.52,
    speed: 0.035,
    size: 20,
    leftToRight: false,
    startOffset: 0.35,
  ),
  FishData(
    yFactor: 0.60,
    speed: 0.045,
    size: 24,
    leftToRight: true,
    startOffset: 0.60,
  ),
  FishData(
    yFactor: 0.70,
    speed: 0.03,
    size: 18,
    leftToRight: false,
    startOffset: 0.15,
  ),
  FishData(
    yFactor: 0.78,
    speed: 0.04,
    size: 22,
    leftToRight: true,
    startOffset: 0.80,
  ),
];

class WaterSceneBackground extends StatelessWidget {
  final AnimationController animation;
  final List<FishData> fish;

  const WaterSceneBackground({
    super.key,
    required this.animation,
    this.fish = defaultFish,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: const _StaticWaterScenePainter(),
            isComplex: false,
            willChange: false,
            child: const SizedBox.expand(),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: _AnimatedWaterScenePainter(animation: animation, fish: fish),
            isComplex: true,
            willChange: true,
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _WaterSceneStyle {
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF9ED8FF),
      Color(0xFF63B8E8),
      Color(0xFF2E86C1),
    ],
  );

  static final Paint waterBandPaint = Paint()
    ..color = const Color.fromARGB(22, 255, 255, 255)
    ..style = PaintingStyle.fill;

  static final Paint groundPaint = Paint()..color = const Color(0xFF3F7D3A);
  static final Paint grassPaint = Paint()..color = const Color(0xFF2E5E2A);
  static final Paint fishBodyA = Paint()..color = const Color(0xFFFFC857);
  static final Paint fishFinA = Paint()..color = const Color(0xCCFFC857);
  static final Paint fishBodyB = Paint()..color = const Color(0xFFEF8354);
  static final Paint fishFinB = Paint()..color = const Color(0xCCEF8354);
  static final Paint eyePaint = Paint()..color = Colors.black;
}

class _StaticWaterScenePainter extends CustomPainter {
  const _StaticWaterScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = _WaterSceneStyle.backgroundGradient.createShader(rect);

    canvas.drawRect(rect, bgPaint);
    _drawStaticGround(canvas, size);
  }

  void _drawStaticGround(Canvas canvas, Size size) {
    final groundTop = size.height * 0.88;
    canvas.drawRect(
      Rect.fromLTWH(0, groundTop, size.width, size.height * 0.12),
      _WaterSceneStyle.groundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StaticWaterScenePainter oldDelegate) => false;
}

class _AnimatedWaterScenePainter extends CustomPainter {
  final AnimationController animation;
  final List<FishData> fish;

  _AnimatedWaterScenePainter({
    required this.animation,
    required this.fish,
  }) : super(repaint: animation);

  static final Map<int, Path> _fishBodyPathCache = <int, Path>{};
  static final Map<int, Path> _fishTailPathCache = <int, Path>{};
  static final Map<int, Path> _fishFinPathCache = <int, Path>{};
  static final Map<int, ui.Picture> _grassPictureCache = <int, ui.Picture>{};

  double get t => animation.value;

  double get elapsedSeconds =>
      (animation.lastElapsedDuration?.inMicroseconds ?? 0) / 1000000.0;

  @override
  void paint(Canvas canvas, Size size) {
    _drawWaterBands(canvas, size);
    _drawFish(canvas, size);
    _drawGrass(canvas, size);
  }

  void _drawWaterBands(Canvas canvas, Size size) {
    final int bandCount = size.height < 700 ? 3 : 4;
    final double stepX = math.max(20.0, size.width / 18.0);

    for (int i = 0; i < bandCount; i++) {
      final path = Path();
      final double baseY = size.height * (0.14 + i * 0.15);
      final double amp = 6.0 + i * 1.5;
      final double wave = 90.0 + i * 18.0;

      path.moveTo(0, baseY);
      for (double x = 0; x <= size.width + stepX; x += stepX) {
        final double y = baseY + math.sin((x / wave) + (t * math.pi * 2) + i) * amp;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, baseY + 22);
      path.lineTo(0, baseY + 22);
      path.close();
      canvas.drawPath(path, _WaterSceneStyle.waterBandPaint);
    }
  }

  void _drawFish(Canvas canvas, Size size) {
    canvas.save();
    final double fishTop = size.height * 0.36;
    final double fishBottom = size.height * 0.86;
    canvas.clipRect(Rect.fromLTRB(0, fishTop, size.width, fishBottom));

    for (int i = 0; i < fish.length; i++) {
      final FishData f = fish[i];
      final double progress = (elapsedSeconds * f.speed + f.startOffset) % 1.0;
      final double swimWidth = size.width + (f.size * 3.0);

      final double x = f.leftToRight
          ? (-f.size * 1.5) + (swimWidth * progress)
          : (size.width + f.size * 1.5) - (swimWidth * progress);

      final double y = size.height * f.yFactor +
          math.sin((elapsedSeconds * 1.8) + i) * 3.5;

      _drawSingleFish(
        canvas,
        Offset(x, y),
        f.size,
        facingRight: f.leftToRight,
        evenIndex: i.isEven,
      );
    }

    canvas.restore();
  }

  void _drawSingleFish(
    Canvas canvas,
    Offset center,
    double size, {
    required bool facingRight,
    required bool evenIndex,
  }) {
    final int key = size.round();
    final Path bodyPath = _fishBodyPathCache.putIfAbsent(key, () => _createFishBodyPath(size));
    final Path tailPath = _fishTailPathCache.putIfAbsent(key, () => _createFishTailPath(size));
    final Path finPath = _fishFinPathCache.putIfAbsent(key, () => _createFishFinPath(size));

    final Paint bodyPaint = evenIndex ? _WaterSceneStyle.fishBodyA : _WaterSceneStyle.fishBodyB;
    final Paint finPaint = evenIndex ? _WaterSceneStyle.fishFinA : _WaterSceneStyle.fishFinB;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (!facingRight) {
      canvas.scale(-1, 1);
    }

    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(tailPath, bodyPaint);
    canvas.drawPath(finPath, finPaint);
    canvas.drawCircle(Offset(size * 0.42, -size * 0.10), size * 0.07, _WaterSceneStyle.eyePaint);
    canvas.restore();
  }

  Path _createFishBodyPath(double size) {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: size * 1.7, height: size * 0.92),
          Radius.circular(size * 0.14),
        ),
      );
  }

  Path _createFishTailPath(double size) {
    return Path()
      ..moveTo(-size * 0.86, 0)
      ..lineTo(-size * 1.28, -size * 0.38)
      ..lineTo(-size * 1.28, size * 0.38)
      ..close();
  }

  Path _createFishFinPath(double size) {
    return Path()
      ..moveTo(-size * 0.08, -size * 0.10)
      ..lineTo(size * 0.18, -size * 0.48)
      ..lineTo(size * 0.36, -size * 0.08)
      ..close();
  }

  void _drawGrass(Canvas canvas, Size size) {
    final int key = ((size.width * 10).round() << 16) ^ (size.height * 10).round();
    final ui.Picture picture = _grassPictureCache.putIfAbsent(
      key,
      () => _recordGrassPicture(size),
    );
    canvas.drawPicture(picture);
  }

  ui.Picture _recordGrassPicture(Size size) {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas cacheCanvas = Canvas(recorder);
    final double groundTop = size.height * 0.88;
    final double stepX = size.width < 420 ? 26.0 : 22.0;

    for (double x = 0; x < size.width + stepX; x += stepX) {
      final double bladeHeight = 14 + 5 * math.sin(x / 24.0).abs();
      final path = Path()
        ..moveTo(x, groundTop)
        ..lineTo(x + 4, groundTop - bladeHeight)
        ..lineTo(x + 8, groundTop)
        ..close();
      cacheCanvas.drawPath(path, _WaterSceneStyle.grassPaint);
    }

    return recorder.endRecording();
  }

  @override
  bool shouldRepaint(covariant _AnimatedWaterScenePainter oldDelegate) {
    return !identical(oldDelegate.animation, animation) || oldDelegate.fish != fish;
  }
}
