import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/game_socket_service.dart';

enum GameFlow {
  armed,
  waitingForBite,
  catching,
  caughtDialog,
}

const bool _enableDebugUi = bool.fromEnvironment(
  'ENABLE_DEBUG_UI',
  defaultValue: false,
);

double calculateMagnitude(double x, double y, double z) {
  return math.sqrt((x * x) + (y * y) + (z * z));
}

double calculateMotion(double x, double y, double z) {
  final magnitude = calculateMagnitude(x, y, z);
  return (magnitude - 9.8).clamp(0.0, double.infinity);
}

bool canCast({
  required bool isConnected,
  required bool isReady,
  required GameFlow flow,
  required bool hasCast,
}) {
  return isConnected &&
      isReady &&
      flow == GameFlow.armed &&
      !hasCast;
}

class Game extends StatefulWidget {
  const Game({super.key});

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> {
  final GameSocketService _socket = GameSocketService.instance;
  late final StreamSubscription<AccelerometerEvent> _accelerometerSubscription;

  GameFlow _flow = GameFlow.armed;
  bool _hasCast = false;
  bool _winDialogShowing = false;
  double _debugAccelX = 0.0;
  double _debugAccelY = 0.0;
  double _debugAccelZ = 0.0;
  double _debugMagnitude = 0.0;
  double _debugMotion = 0.0;
  bool _debugCanCast = false;

  static const double _castThreshold = 5.0;

  @override
  void initState() {
    super.initState();
    _socket.addListener(_handleSocketChanged);
    _accelerometerSubscription = accelerometerEventStream().listen(_onAccelerometer);
  }

  @override
  void dispose() {
    _socket.removeListener(_handleSocketChanged);
    _accelerometerSubscription.cancel();
    super.dispose();
  }

  void _handleSocketChanged() {
    if (!mounted) return;

    final socketState = _socket.gameState;

    if (socketState == 'bite' && _flow == GameFlow.waitingForBite) {
      setState(() {
        _flow = GameFlow.catching;
        _hasCast = false;
      });
      return;
    }

    if (socketState == 'caught') {
      setState(() {
        _flow = GameFlow.caughtDialog;
        _hasCast = false;
        _winDialogShowing = true;
      });
      return;
    }

    if (socketState == 'none' && _flow == GameFlow.caughtDialog) {
      return;
    }

    setState(() {});
  }

  void _onAccelerometer(AccelerometerEvent event) {
    final magnitude = calculateMagnitude(event.x, event.y, event.z);
    final motion = calculateMotion(event.x, event.y, event.z);

    final canUserCast = canCast(
      isConnected: _socket.isConnected,
      isReady: _socket.isReady,
      flow: _flow,
      hasCast: _hasCast,
    );

    if (mounted) {
      setState(() {
        _debugAccelX = event.x;
        _debugAccelY = event.y;
        _debugAccelZ = event.z;
        _debugMagnitude = magnitude;
        _debugMotion = motion;
        _debugCanCast = canUserCast;
      });
    }

    if (!canUserCast) {
      return;
    }

    if (motion < _castThreshold) {
      return;
    }

    _hasCast = true;
    setState(() {
      _flow = GameFlow.waitingForBite;
    });
    _socket.sendAction('fish');
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleCatchWin() async {
    if (_winDialogShowing || !mounted) return;

    setState(() {
      _winDialogShowing = true;
      _flow = GameFlow.caughtDialog;
      _hasCast = false;
    });

    _socket.sendAction('catch');
  }

  Future<void> _handleCaughtDismissed() async {
    if (!mounted) return;

    setState(() {
      _winDialogShowing = false;
    });

    _socket.sendAction('caught');
    await _socket.disconnect(notify: false);

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  Widget _buildCastingPage(TextStyle titleStyle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Casting page',
              textAlign: TextAlign.center,
              style: titleStyle.copyWith(fontSize: 21),
            ),
            const SizedBox(height: 12),
            Text(
              'Move the phone like a casting motion to send fish.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_enableDebugUi) ...[
              const SizedBox(height: 12),
              _buildDebugTelemetryCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingPage(TextStyle titleStyle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Waiting for a bite',
              textAlign: TextAlign.center,
              style: titleStyle.copyWith(fontSize: 21),
            ),
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The line is in the water. Wait for bite before the minigame appears.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaughtPage(TextStyle titleStyle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Fish caught',
              textAlign: TextAlign.center,
              style: titleStyle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 12),
            Text(
              'You caught the fish. Dismiss this page to send caught and return home.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _handleCaughtDismissed,
              child: const Text('Return Home'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _backToHome() async {
    await _socket.disconnect(notify: false);
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  Widget _buildStatusCard(TextStyle titleStyle, TextStyle valueStyle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connection: ${_socket.connectionLabel}', style: titleStyle),
            const SizedBox(height: 4),
            Text('Ready: ${_socket.isReady ? 'yes' : 'no'}', style: valueStyle),
            const SizedBox(height: 4),
            Text('State: ${_socket.gameState}', style: valueStyle),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugTelemetryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cast debug: ${_debugCanCast ? 'armed' : 'blocked'}'),
              const SizedBox(height: 4),
              Text('X: ${_debugAccelX.toStringAsFixed(2)}'),
              Text('Y: ${_debugAccelY.toStringAsFixed(2)}'),
              Text('Z: ${_debugAccelZ.toStringAsFixed(2)}'),
              Text('Magnitude: ${_debugMagnitude.toStringAsFixed(2)}'),
              Text('Motion: ${_debugMotion.toStringAsFixed(2)} / $_castThreshold'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatchPanel() {
    return SizedBox(
      height: math.max(430.0, MediaQuery.sizeOf(context).height * 0.58),
      child: _CatchMiniGame(onWin: _handleCatchWin),
    );
  }

  Widget _buildEventLog() {
    final events = _socket.events;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Event Log',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  reverse: true,
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        events[index],
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
    final bodyStyle = theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fishing Game'),
        actions: [
          IconButton(
            onPressed: _backToHome,
            icon: const Icon(Icons.home),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_enableDebugUi) ...[
                _buildStatusCard(titleStyle, bodyStyle),
                const SizedBox(height: 12),
              ],
              if (_flow == GameFlow.catching)
                _buildCatchPanel()
              else if (_flow == GameFlow.caughtDialog)
                _buildCaughtPage(titleStyle)
              else if (_flow == GameFlow.waitingForBite)
                _buildWaitingPage(titleStyle)
              else
                _buildCastingPage(titleStyle),
              if (_enableDebugUi) ...[
                const SizedBox(height: 12),
                _buildEventLog(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CatchMiniGame extends StatefulWidget {
  final VoidCallback onWin;

  const _CatchMiniGame({required this.onWin});

  @override
  State<_CatchMiniGame> createState() => _CatchMiniGameState();
}

class _CatchMiniGameState extends State<_CatchMiniGame> with TickerProviderStateMixin {
  double progress = 0.3;
  late final AnimationController _zoneController;
  late final Ticker _fishTicker;

  bool _isPressing = false;
  bool _won = false;

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
  static const double _whiteLossPerSecond = 0.08;

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
    if (!mounted || _won) return;

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

    if ((nextFishTop - _fishTop).abs() > 0.01 ||
        (nextProgress - progress).abs() > 0.0005) {
      setState(() {
        _fishTop = nextFishTop;
        progress = nextProgress;
      });
    }

    if (nextProgress >= 1.0 && !_won) {
      _won = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onWin();
        }
      });
    }
  }

  void _setPressing(bool value) {
    if (_won) return;
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

    final horizontalPadding = sw * 0.06;

    final meterOuterHeight = sh * 0.72;
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueGrey.shade900,
            const Color(0xFF0B3D2E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _setPressing(true),
        onPointerUp: (_) => _setPressing(false),
        onPointerCancel: (_) => _setPressing(false),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              SizedBox(height: safeTop + 8),
              Text(
                'Bite! Hold to reel the fish in.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: sw * 0.82,
                height: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD54F)),
                  ),
                ),
              ),
              SizedBox(height: sh * 0.02),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/home',
                                  (route) => false,
                                );
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back to home'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xCC000000),
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Hold the screen to keep the line tight.\nRelease to let it drop.\nRed is best, then yellow, then green.',
                                  textAlign: TextAlign.center,
                                  style:
                                      Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Colors.white,
                                            height: 1.25,
                                            fontWeight: FontWeight.w600,
                                          ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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