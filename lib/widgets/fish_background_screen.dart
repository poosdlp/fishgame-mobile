import 'package:flutter/material.dart';

import 'water_scene.dart';

class FishBackgroundScreen extends StatefulWidget {
  const FishBackgroundScreen({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 12),
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = widget.child;

    if (widget.scrollable) {
      content = SingleChildScrollView(child: content);
    }

    if (widget.useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          WaterSceneBackground(animation: _controller),
          content,
        ],
      ),
    );
  }
}