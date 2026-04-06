import 'dart:math' as math;

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
  FishData(yFactor: 0.42, speed: 0.05, size: 26, leftToRight: true, startOffset: 0.00),
  FishData(yFactor: 0.52, speed: 0.035, size: 20, leftToRight: false, startOffset: 0.35),
  FishData(yFactor: 0.60, speed: 0.045, size: 24, leftToRight: true, startOffset: 0.60),
  FishData(yFactor: 0.70, speed: 0.03, size: 18, leftToRight: false, startOffset: 0.15),
  FishData(yFactor: 0.78, speed: 0.04, size: 22, leftToRight: true, startOffset: 0.80),
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
    return RepaintBoundary(
      child: CustomPaint(
        painter: WaterScenePainter(animation: animation, fish: fish),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class WaterScenePainter extends CustomPainter {
  final AnimationController animation;
  final List<FishData> fish;

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF9ED8FF),
      Color(0xFF63B8E8),
      Color(0xFF2E86C1),
    ],
  );

  WaterScenePainter({
    required this.animation,
    required this.fish,
  }) : super(repaint: animation);

  double get t => animation.value;

  double get elapsedSeconds =>
      (animation.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()..shader = backgroundGradient.createShader(rect);

    canvas.drawRect(rect, bgPaint);
    _drawWaterBands(canvas, size);
    _drawFish(canvas, size);
    _drawGrass(canvas, size);
  }

  void _drawWaterBands(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(30, 255, 255, 255)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final baseY = size.height * (0.12 + i * 0.13);
      final amp = 8.0 + i * 2.0;
      final wave = 70.0 + i * 14.0;

      path.moveTo(0, baseY);
      for (double x = 0; x <= size.width; x += 16) {
        final y = baseY + math.sin((x / wave) + (t * math.pi * 2) + i) * amp;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, baseY + 26);
      path.lineTo(0, baseY + 26);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawFish(Canvas canvas, Size size) {
    canvas.save();
    final fishTop = size.height * 0.36;
    final fishBottom = size.height * 0.86;
    canvas.clipRect(Rect.fromLTRB(0, fishTop, size.width, fishBottom));

    for (int i = 0; i < fish.length; i++) {
      final f = fish[i];
      final progress = (elapsedSeconds * f.speed + f.startOffset) % 1.0;
      final swimWidth = size.width + (f.size * 3.0);

      final x = f.leftToRight
          ? (-f.size * 1.5) + (swimWidth * progress)
          : (size.width + f.size * 1.5) - (swimWidth * progress);

      final y = size.height * f.yFactor + math.sin((elapsedSeconds * 2.2) + i) * 6;

      _drawSingleFish(
        canvas,
        Offset(x, y),
        f.size,
        facingRight: f.leftToRight,
        color: i.isEven ? const Color(0xFFFFC857) : const Color(0xFFEF8354),
      );
    }

    canvas.restore();
  }

  void _drawSingleFish(
    Canvas canvas,
    Offset center,
    double size, {
    required bool facingRight,
    required Color color,
  }) {
    final bodyPaint = Paint()..color = color;
    final finPaint = Paint()..color = Color.fromARGB(204, color.red, color.green, color.blue);
    final eyePaint = Paint()..color = Colors.black;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    if (!facingRight) {
      canvas.scale(-1, 1);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: size * 1.8, height: size),
        Radius.circular(size * 0.15),
      ),
      bodyPaint,
    );

    final tail = Path()
      ..moveTo(-size * 0.9, 0)
      ..lineTo(-size * 1.35, -size * 0.45)
      ..lineTo(-size * 1.35, size * 0.45)
      ..close();
    canvas.drawPath(tail, bodyPaint);

    final fin = Path()
      ..moveTo(-size * 0.15, -size * 0.15)
      ..lineTo(size * 0.2, -size * 0.65)
      ..lineTo(size * 0.45, -size * 0.1)
      ..close();
    canvas.drawPath(fin, finPaint);

    canvas.drawCircle(Offset(size * 0.45, -size * 0.12), size * 0.08, eyePaint);
    canvas.restore();
  }

  void _drawGrass(Canvas canvas, Size size) {
    final groundPaint = Paint()..color = const Color(0xFF3F7D3A);
    final bladePaint = Paint()..color = const Color(0xFF2E5E2A);
    final groundTop = size.height * 0.88;

    canvas.drawRect(
      Rect.fromLTWH(0, groundTop, size.width, size.height * 0.12),
      groundPaint,
    );

    for (double x = 0; x < size.width; x += 20) {
      final bladeHeight = 12 + 10 * math.sin((x / 18) + t * math.pi * 2).abs();
      final path = Path()
        ..moveTo(x, groundTop)
        ..lineTo(x + 4, groundTop - bladeHeight)
        ..lineTo(x + 8, groundTop)
        ..close();
      canvas.drawPath(path, bladePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
