import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class Game extends StatefulWidget {
  const Game({super.key});

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> with TickerProviderStateMixin {
  double progress = 0.3;
  late final AnimationController _zoneController;
  late final Ticker _fishTicker;

  bool _isPressing = false;
  Duration? _lastTick;

  double _fishTop = 0;

  double _meterInnerHeight = 0;
  double _fishSize = 0;
  double _zoneTravelPerSecond = 0;

  double _greenZoneHeight = 0;
  double _yellowZoneHeight = 0;
  double _redZoneHeight = 0;
  double _currentZoneTop = 0;

  static const double _redGainPerSecond = 0.42;
  static const double _yellowGainPerSecond = 0.22;
  static const double _greenGainPerSecond = 0.10;
  static const double _whiteLossPerSecond = 0.18;

  @override
  void initState() {
    super.initState();
    _zoneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )
      ..addListener(() {
        final maxTravel = math.max(0.0, _meterInnerHeight - _greenZoneHeight);
        _currentZoneTop = (_zoneController.value * maxTravel).clamp(0.0, maxTravel);
      })
      ..repeat(reverse: true);

    _fishTicker = createTicker(_onFishTick)..start();
  }

  void _onFishTick(Duration elapsed) {
    if (!mounted) return;

    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;

    if (_meterInnerHeight <= 0 || _fishSize <= 0) return;

    final dt = (elapsed - last).inMicroseconds / Duration.microsecondsPerSecond;
    if (dt <= 0) return;

    final maxFishTop = math.max(0.0, _meterInnerHeight - _fishSize);

    final upwardVelocity = _zoneTravelPerSecond * 1.25;
    final downwardVelocity = _zoneTravelPerSecond;

    final movementDelta = (_isPressing ? -upwardVelocity : downwardVelocity) * dt;
    final nextFishTop = (_fishTop + movementDelta).clamp(0.0, maxFishTop);

    final fishCenter = nextFishTop + (_fishSize / 2);

    final greenTop = _currentZoneTop;
    final greenBottom = greenTop + _greenZoneHeight;

    final yellowTop = greenTop + ((_greenZoneHeight - _yellowZoneHeight) / 2);
    final yellowBottom = yellowTop + _yellowZoneHeight;

    final redTop = yellowTop + ((_yellowZoneHeight - _redZoneHeight) / 2);
    final redBottom = redTop + _redZoneHeight;

    double progressRate;
    if (fishCenter >= redTop && fishCenter <= redBottom) {
      progressRate = _redGainPerSecond;
    } else if (fishCenter >= yellowTop && fishCenter <= yellowBottom) {
      progressRate = _yellowGainPerSecond;
    } else if (fishCenter >= greenTop && fishCenter <= greenBottom) {
      progressRate = _greenGainPerSecond;
    } else {
      progressRate = -_whiteLossPerSecond;
    }

    final nextProgress = (progress + (progressRate * dt)).clamp(0.0, 1.0);

    if ((nextFishTop - _fishTop).abs() > 0.01 || (nextProgress - progress).abs() > 0.0005) {
      setState(() {
        _fishTop = nextFishTop;
        progress = nextProgress;
      });
    }
  }

  void _setPressing(bool value) {
    if (_isPressing == value) return;
    setState(() {
      _isPressing = value;
    });
  }

  @override
  void dispose() {
    _fishTicker.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final sw = size.width;
    final sh = size.height;
    final safeTop = media.padding.top;

    final horizontalPadding = sw * 0.08;

    final meterOuterHeight = sh * 0.75;
    final meterOuterWidth = math.max(64.0, sw * 0.19);
    final meterPadding = math.max(6.0, meterOuterWidth * 0.09);

    final meterInnerWidth = meterOuterWidth - (meterPadding * 2);
    final meterInnerHeight = meterOuterHeight - (meterPadding * 2);

    final greenZoneHeight = meterInnerHeight * 0.28;
    final yellowZoneHeight = greenZoneHeight * 0.55;
    final redZoneHeight = yellowZoneHeight * 0.45;
    final maxTravel = math.max(0.0, meterInnerHeight - greenZoneHeight);

    final fishHeight = math.max(12.0, redZoneHeight * 0.75);
    final fishWidth = fishHeight * 1.5;

    _meterInnerHeight = meterInnerHeight;
    _fishSize = fishHeight;
    _greenZoneHeight = greenZoneHeight;
    _yellowZoneHeight = yellowZoneHeight;
    _redZoneHeight = redZoneHeight;
    _zoneTravelPerSecond =
        maxTravel / (_zoneController.duration!.inMilliseconds / 1000.0);

    final maxFishTop = math.max(0.0, _meterInnerHeight - _fishSize);
    if (_fishTop > maxFishTop) {
      _fishTop = maxFishTop;
    }

    final progressContainerWidth = sw * 0.82;
    final progressContainerHeight = (sh * 0.065).clamp(42.0, 56.0);
    final topGap = (sh * 0.01).clamp(4.0, 10.0);
    final bottomGap = (sh * 0.008).clamp(2.0, 8.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0B3D2E),
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _setPressing(true),
        onPointerUp: (_) => _setPressing(false),
        onPointerCancel: (_) => _setPressing(false),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              SizedBox(height: safeTop),
              SizedBox(
                width: progressContainerWidth,
                height: progressContainerHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/progress_container.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      left: progressContainerWidth * (1 / 31),
                      top: progressContainerHeight * (9 / 16),
                      child: ClipRect(
                        child: SizedBox(
                          width: (progressContainerWidth * (15 / 16)) * progress,
                          height: progressContainerHeight * (5 / 16),
                          child: Image.asset(
                            'assets/progress.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: topGap),
              SizedBox(
                height: meterOuterHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: meterOuterWidth,
                      height: meterOuterHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55000000),
                              blurRadius: 10,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(meterPadding),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedBuilder(
                                    animation: _zoneController,
                                    builder: (context, child) {
                                      final topOffset =
                                          (_zoneController.value * maxTravel)
                                              .clamp(0.0, maxTravel);
                                      _currentZoneTop = topOffset;
                                      return Stack(
                                        children: [
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            top: topOffset,
                                            child: child!,
                                          ),
                                        ],
                                      );
                                    },
                                    child: _AccuracyZone(
                                      width: meterInnerWidth,
                                      greenHeight: greenZoneHeight,
                                      yellowHeight: yellowZoneHeight,
                                      redHeight: redZoneHeight,
                                    ),
                                  ),
                                  Positioned(
                                    left: (meterInnerWidth - fishWidth) / 2,
                                    top: _fishTop,
                                    child: _PixelFishSprite(
                                      width: fishWidth,
                                      height: fishHeight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: sw * 0.08),
                    Expanded(
                      child: SizedBox(
                        height: meterOuterHeight,
                        child: Center(
                          child: Text(
                            'Fishing Reel Meter\n\nHold screen = fish rises\nRelease = fish falls\nRed = best timing\nYellow = good timing\nGreen = low-score timing\nWhite = miss zone',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  height: 1.25,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: bottomGap),
              Expanded(
                child: Center(
                  child: Slider(
                    value: progress,
                    min: 0,
                    max: 1,
                    onChanged: (value) {
                      setState(() {
                        progress = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccuracyZone extends StatelessWidget {
  const _AccuracyZone({
    required this.width,
    required this.greenHeight,
    required this.yellowHeight,
    required this.redHeight,
  });

  final double width;
  final double greenHeight;
  final double yellowHeight;
  final double redHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: greenHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            height: greenHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF23C552),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(
            width: double.infinity,
            height: yellowHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(
            width: double.infinity,
            height: redHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _PixelFishSprite extends StatelessWidget {
  const _PixelFishSprite({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _PixelFishPainter(),
      ),
    );
  }
}

class _PixelFishPainter extends CustomPainter {
  static const List<String> _rows = [
    '000001110000',
    '000112221000',
    '011222222110',
    '122222333221',
    '123222333331',
    '122222333221',
    '011222222110',
    '000112221000',
    '000001110000',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final pixelW = size.width / _rows.first.length;
    final pixelH = size.height / _rows.length;

    final colors = <String, Color>{
      '0': Colors.transparent,
      '1': const Color(0xFF0D47A1),
      '2': const Color(0xFF1E88E5),
      '3': const Color(0xFF64B5F6),
    };

    for (var y = 0; y < _rows.length; y++) {
      final row = _rows[y];
      for (var x = 0; x < row.length; x++) {
        final key = row[x];
        if (key == '0') continue;

        final paint = Paint()..color = colors[key]!;
        canvas.drawRect(
          Rect.fromLTWH(
            x * pixelW,
            y * pixelH,
            pixelW,
            pixelH,
          ),
          paint,
        );
      }
    }

    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = Colors.black;

    canvas.drawRect(
      Rect.fromLTWH(pixelW * 8, pixelH * 3, pixelW, pixelH),
      eyePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(pixelW * 8.4, pixelH * 3.3, pixelW * 0.45, pixelH * 0.45),
      pupilPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
