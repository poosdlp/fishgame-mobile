import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SpeedPage extends StatefulWidget {
  const SpeedPage({super.key});

  @override
  State<SpeedPage> createState() => _SpeedPageState();
}

class _SpeedPageState extends State<SpeedPage> {
  double _speed = 0.0;
  bool _isTouching = false;

  @override
  void initState() {
    super.initState();
    accelerometerEventStream().listen((event) {
      if (!_isTouching) return;
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      setState(() {
        _speed = (magnitude - 9.8).clamp(0, double.infinity);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => setState(() => _isTouching = true),
        onPointerUp: (_) => setState(() { _isTouching = false; _speed = 0.0; }),
        onPointerCancel: (_) => setState(() { _isTouching = false; _speed = 0.0; }),
        child: Center(
          child: Text(
            _speed.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 96,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
