import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/game_socket_service.dart';
import '../widgets/fish_background_screen.dart';

enum _GameFlow {
  casting,
  waiting,
  bite,
  minigame,
  lost,
  caught,
}

const bool _enableDebugUi = bool.fromEnvironment(
  'ENABLE_DEBUG_UI',
  defaultValue: false,
);

class Game extends StatefulWidget {
  const Game({super.key});

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> {
  final GameSocketService _socket = GameSocketService.instance;
  late final StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  Timer? _loseReturnTimer;

  _GameFlow _flow = _GameFlow.casting;
  bool _motionLocked = false;

  double _debugAccelX = 0.0;
  double _debugAccelY = 0.0;
  double _debugAccelZ = 0.0;
  double _debugMagnitude = 0.0;
  double _debugMotion = 0.0;
  String _debugPhase = 'casting';

  static const double _motionThreshold = 5.0;

  @override
  void initState() {
    super.initState();
    _socket.addListener(_handleSocketChanged);
    _accelerometerSubscription = accelerometerEventStream().listen(_onAccelerometer);
  }

  @override
  void dispose() {
    _loseReturnTimer?.cancel();
    _socket.removeListener(_handleSocketChanged);
    _accelerometerSubscription.cancel();
    super.dispose();
  }

  void _handleSocketChanged() {
    if (!mounted) return;

    final state = _socket.gameState;

    if (state == 'bite' && _flow == _GameFlow.waiting) {
      setState(() {
        _flow = _GameFlow.bite;
        _motionLocked = false;
        _debugPhase = 'bite';
      });
      return;
    }

    if (state == 'none' && (_flow == _GameFlow.waiting || _flow == _GameFlow.bite)) {
      setState(() {
        _flow = _GameFlow.casting;
        _motionLocked = false;
        _debugPhase = 'casting';
      });
      return;
    }

    if (state == 'caught') {
      setState(() {
        _flow = _GameFlow.caught;
        _motionLocked = false;
        _debugPhase = 'caught';
      });
      return;
    }

    setState(() {});
  }

  void _onAccelerometer(AccelerometerEvent event) {
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    final motion = (magnitude - 9.8).clamp(0.0, double.infinity);
    debugPrint(
      'Motion: ${motion.toStringAsFixed(3)} | Threshold: ${_motionThreshold.toStringAsFixed(3)}',
    );

    final canUseMotion = _socket.isConnected &&
      _socket.isReady &&
      (_flow == _GameFlow.casting ||
        _flow == _GameFlow.waiting ||
        _flow == _GameFlow.bite) &&
      !_motionLocked;

    if (mounted) {
      setState(() {
        _debugAccelX = event.x;
        _debugAccelY = event.y;
        _debugAccelZ = event.z;
        _debugMagnitude = magnitude;
        _debugMotion = motion;
      });
    }

    if (!canUseMotion || motion < _motionThreshold) {
      return;
    }

    _motionLocked = true;

    if (_flow == _GameFlow.casting) {
      _socket.sendAction('fish');
      setState(() {
        _flow = _GameFlow.waiting;
        _debugPhase = 'waiting';
      });
      return;
    }

    if (_flow == _GameFlow.waiting) {
      _socket.sendAction('reel');
      setState(() {
        _debugPhase = 'waiting';
      });
      return;
    }

    if (_flow == _GameFlow.bite) {
      setState(() {
        _flow = _GameFlow.minigame;
        _debugPhase = 'minigame';
      });
    }
  }

  Future<void> _onMinigameWin() async {
    if (!mounted) return;

    _loseReturnTimer?.cancel();
    _socket.sendAction('catch');
    setState(() {
      _flow = _GameFlow.caught;
      _motionLocked = false;
      _debugPhase = 'caught';
    });
  }

  Future<void> _onMinigameLose() async {
    if (!mounted) return;

    _socket.sendAction('reel');
    setState(() {
      _flow = _GameFlow.lost;
      _motionLocked = false;
      _debugPhase = 'lost';
    });

    _loseReturnTimer?.cancel();
    _loseReturnTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    });
  }

  Future<void> _finishCaughtAndReturnHome() async {
    _socket.sendAction('caught');

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  Future<void> _backToHome() async {
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  Widget _buildImmersivePage({
    required String title,
    required String subtitle,
    List<Widget> children = const [],
  }) {
    final size = MediaQuery.sizeOf(context);
    final sw = size.width;

    final titleStyle = GoogleFonts.pixelifySans(
      fontSize: sw * 0.11,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFFF5F87),
      height: 0.95,
      shadows: const [
        Shadow(color: Color(0x99000000), offset: Offset(3, 3), blurRadius: 0),
      ],
    );

    final messageStyle = GoogleFonts.pixelifySans(
      fontSize: sw * 0.06,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      shadows: const [
        Shadow(color: Color(0x80000000), offset: Offset(2, 2), blurRadius: 0),
      ],
    );

    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: titleStyle,
                ),
                const SizedBox(height: 14),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: messageStyle,
                ),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCastingPage() {
    return _buildImmersivePage(
      title: 'Casting',
      subtitle: 'Make a casting motion with your phone to throw the line.',
    );
  }

  Widget _buildWaitingPage() {
    return _buildImmersivePage(
      title: 'Waiting',
      subtitle: 'Your line is in the water. Wait until a fish bites.',
    );
  }

  Widget _buildBitePage() {
    return _buildImmersivePage(
      title: 'Bite!',
      subtitle: 'Fish on the hook. Make the same casting motion to start reeling.',
    );
  }

  Widget _buildCaughtPage() {
    return _buildImmersivePage(
      title: 'Fish Caught',
      subtitle: 'Nice catch. Finish to return to Home.',
      children: [
        SizedBox(
          width: 220,
          height: 56,
          child: ElevatedButton(
            onPressed: _finishCaughtAndReturnHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Finish',
              style: GoogleFonts.pixelifySans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLostPage() {
    return _buildImmersivePage(
      title: 'You Lost',
      subtitle: 'The fish got away. Returning to Home...',
      children: const [
        Icon(Icons.sentiment_dissatisfied, size: 72, color: Colors.white),
      ],
    );
  }

  Widget _buildDebugCard() {
    final events = _socket.events;

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Socket: ${_socket.connectionLabel}'),
            Text('Ready: ${_socket.isReady}'),
            Text('WS state: ${_socket.gameState}'),
            Text('Flow: $_debugPhase'),
            Text('X: ${_debugAccelX.toStringAsFixed(2)}'),
            Text('Y: ${_debugAccelY.toStringAsFixed(2)}'),
            Text('Z: ${_debugAccelZ.toStringAsFixed(2)}'),
            Text('Magnitude: ${_debugMagnitude.toStringAsFixed(2)}'),
            Text('Motion: ${_debugMotion.toStringAsFixed(2)} / $_motionThreshold'),
            const SizedBox(height: 8),
            const Text('Events', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            SizedBox(
              height: 130,
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
    Widget body;

    switch (_flow) {
      case _GameFlow.casting:
        body = _buildCastingPage();
      case _GameFlow.waiting:
        body = _buildWaitingPage();
      case _GameFlow.bite:
        body = _buildBitePage();
      case _GameFlow.minigame:
        body = _CatchMiniGame(
          onWin: _onMinigameWin,
          onLose: _onMinigameLose,
        );
      case _GameFlow.lost:
        body = _buildLostPage();
      case _GameFlow.caught:
        body = _buildCaughtPage();
    }

    return FishBackgroundScreen(
      useSafeArea: false,
      scrollable: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Fishing Game',
            style: GoogleFonts.pixelifySans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _backToHome,
              icon: const Icon(Icons.home),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Expanded(child: body),
            if (_enableDebugUi) _buildDebugCard(),
          ],
        ),
      ),
    );
  }
}

class _CatchMiniGame extends StatefulWidget {
  final VoidCallback onWin;
  final VoidCallback onLose;

  const _CatchMiniGame({
    required this.onWin,
    required this.onLose,
  });

  @override
  State<_CatchMiniGame> createState() => _CatchMiniGameState();
}

class _CatchMiniGameState extends State<_CatchMiniGame> with TickerProviderStateMixin {
  double progress = 0.3;
  late final AnimationController _zoneController;
  late final Ticker _fishTicker;

  bool _isPressing = false;
  bool _won = false;
  bool _lost = false;

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
    if (!mounted || _won || _lost) return;

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

    if (nextProgress <= 0.0 && !_lost) {
      _lost = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onLose();
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

    final horizontalPadding = sw * 0.06;

    final meterOuterHeight = sh * 0.54;
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

    return SizedBox(
      width: double.infinity,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _setPressing(true),
        onPointerUp: (_) => _setPressing(false),
        onPointerCancel: (_) => _setPressing(false),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
              Text(
                'Reel In!',
                textAlign: TextAlign.center,
                style: GoogleFonts.pixelifySans(
                  fontSize: sw * 0.075,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: Color(0x80000000), offset: Offset(2, 2), blurRadius: 0),
                  ],
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
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(meterPadding),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: DecoratedBox(
                              decoration: const BoxDecoration(color: Colors.white),
                              child: Stack(
                                children: [
                                  AnimatedBuilder(
                                    animation: _zoneController,
                                    builder: (context, child) {
                                      final topOffset =
                                          (_zoneController.value * maxTravel)
                                              .clamp(0.0, maxTravel);
                                      _currentZoneTop = topOffset;
                                      return Positioned(
                                        left: 0,
                                        right: 0,
                                        top: topOffset,
                                        child: child!,
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
                      child: Text(
                        'Hold screen = fish rises\nRelease = fish falls\nFill meter to win.',
                        style: GoogleFonts.pixelifySans(
                          fontSize: sw * 0.05,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Color(0x80000000), offset: Offset(2, 2), blurRadius: 0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                    ],
                  ),
                ),
              ),
            );
          },
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
            color: const Color(0xFF23C552),
          ),
          Container(
            width: double.infinity,
            height: yellowHeight,
            color: const Color(0xFFFFD54F),
          ),
          Container(
            width: double.infinity,
            height: redHeight,
            color: const Color(0xFFE53935),
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
