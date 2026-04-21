import 'package:flutter/material.dart';

import 'water_scene.dart';

class FishBackgroundScreen extends StatefulWidget {
  const FishBackgroundScreen({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 8),
    this.useSafeArea = true,
    this.scrollable = true,
  });

  final Widget child;
  final Duration duration;
  final bool useSafeArea;
  final bool scrollable;

  @override
  State<FishBackgroundScreen> createState() => _FishBackgroundScreenState();
}

class _FishBackgroundScreenState extends State<FishBackgroundScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant FishBackgroundScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = RepaintBoundary(child: widget.child);

    if (widget.scrollable) {
      content = SingleChildScrollView(child: content);
    }

    if (widget.useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      body: TickerMode(
        enabled: TickerMode.valuesOf(context).enabled,
        child: Stack(
          fit: StackFit.expand,
          children: [
            WaterSceneBackground(animation: _controller),
            content,
          ],
        ),
      ),
    );
  }
}
