import 'package:flutter/material.dart';

class Game extends StatefulWidget {
  const Game({super.key});

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> with SingleTickerProviderStateMixin {
  double progress = 0.3;
  late AnimationController _barController;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  void _toggleBarMovement() {
    if (_barController.isAnimating) {
      _barController.stop();
    } else {
      _barController.repeat(reverse: true);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double sw = size.width;
    final double sh = size.height;

    final double containerLeft = sw * 0.1;
    final double containerTop = sh * 0.05;
    final double containerWidth = sw * 0.8;
    final double containerHeight = sh * 0.1;

    final double gameBarWidth = sw * 0.8;
    final double gameBarHeight = sh * 0.04;
    final double innerBarHeight = gameBarHeight * (9 / 11);

    final double movingBarWidth = gameBarWidth * 0.35;

    final double minBarLeft = gameBarWidth * (1 / 31);
    final double maxBarLeft = gameBarWidth - minBarLeft - movingBarWidth;

    final double greenWidth = movingBarWidth;
    final double yellowWidth = movingBarWidth * 0.6;
    final double redWidth = movingBarWidth * 0.3;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: Colors.green[50] ?? Colors.green,
            ),
          ),

          // Top progress bar
          Positioned(
            left: containerLeft,
            top: containerTop,
            child: SizedBox(
              width: containerWidth,
              height: containerHeight,
              child: Stack(
                children: [
                  Image.asset(
                    "assets/progress_container.png",
                    width: containerWidth,
                    height: containerHeight,
                    fit: BoxFit.fill,
                  ),
                  Positioned(
                    left: containerWidth * (1 / 31),
                    top: containerHeight * (9 / 16),
                    child: ClipRect(
                      child: SizedBox(
                        width: (containerWidth * (15 / 16)) * progress,
                        height: containerHeight * (5 / 16),
                        child: Image.asset(
                          "assets/progress.png",
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Game bar container + moving stack
          Positioned(
            top: containerTop + sh * 0.12,
            left: containerLeft,
            child: SizedBox(
              width: gameBarWidth,
              height: gameBarHeight,
              child: Stack(
                children: [
                  Image.asset(
                    'assets/game_bar_container.png',
                    width: gameBarWidth,
                    height: gameBarHeight,
                    fit: BoxFit.fill,
                  ),

                  Positioned(
                    left: minBarLeft,
                    top: (gameBarHeight - innerBarHeight) / 2,
                    child: AnimatedBuilder(
                      animation: _barController,
                      builder: (context, child) {
                        final double dx =
                            (maxBarLeft - minBarLeft) * _barController.value;

                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: movingBarWidth,
                        height: innerBarHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            
                            // Green
                            Image.asset(
                              'assets/green_bar.png',
                              width: greenWidth,
                              height: innerBarHeight,
                              fit: BoxFit.fill,
                            ),

                            // Yellow
                            Image.asset(
                              'assets/yellow_bar.png',
                              width: yellowWidth,
                              height: innerBarHeight,
                              fit: BoxFit.fill,
                            ),

                            // Red
                            Image.asset(
                              'assets/red_bar.png',
                              width: redWidth,
                              height: innerBarHeight,
                              fit: BoxFit.fill,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Button
          Positioned(
            top: containerTop + sh * 0.12 + gameBarHeight + 20,
            left: containerLeft,
            child: SizedBox(
              width: gameBarWidth,
              child: ElevatedButton(
                onPressed: _toggleBarMovement,
                child: Text(_barController.isAnimating ? 'Stop' : 'Start'),
              ),
            ),
          ),

          // Slider
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Slider(
              value: progress,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                setState(() {
                  progress = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}