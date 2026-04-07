import 'dart:math' as math;

import 'package:flutter/material.dart';

class Game extends StatefulWidget {
  const Game({super.key});

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> with SingleTickerProviderStateMixin {
  double progress = 0.3;
  late final AnimationController _zoneController;

  @override
  void initState() {
    super.initState();
    _zoneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _zoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final sw = size.width;
    final sh = size.height;

    final horizontalPadding = sw * 0.08;

    final meterOuterHeight = sh * 0.7;
    final meterOuterWidth = math.max(54.0, sw * 0.16);
    final meterPadding = math.max(6.0, meterOuterWidth * 0.09);

    final meterInnerWidth = meterOuterWidth - (meterPadding * 2);
    final meterInnerHeight = meterOuterHeight - (meterPadding * 2);

    final greenZoneHeight = meterInnerHeight * 0.28;
    final yellowZoneHeight = greenZoneHeight * 0.55;
    final redZoneHeight = yellowZoneHeight * 0.45;
    final maxTravel = math.max(0.0, meterInnerHeight - greenZoneHeight);

    final progressContainerWidth = sw * 0.82;
    final progressContainerHeight = (sh * 0.1);
    final bottomGap = (sh * 0.008).clamp(2.0, 8.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0B3D2E),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          children: [
            SizedBox(height: sh*0.05),
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
            SizedBox(height: sh*0.05),
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
                            child: AnimatedBuilder(
                              animation: _zoneController,
                              builder: (context, child) {
                                final topOffset = (_zoneController.value * maxTravel)
                                    .clamp(0.0, maxTravel);
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
                          'Fishing Reel Meter\n\nRed = best timing\nYellow = good timing\nGreen = low-score timing\nWhite = miss zone',
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
