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
  bool _thresholdTriggered = false;

  static const double _threshold = 10.0;

  @override
  void initState() {
    super.initState();
    accelerometerEventStream().listen((event) {
      if (!_isTouching) return;
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final speed = (magnitude - 9.8).clamp(0.0, double.infinity);
      setState(() {
        _speed = speed;
      });
      if (speed >= _threshold && !_thresholdTriggered) {
        _thresholdTriggered = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speed threshold reached :D'),
            ),
          );
        }
      } else if (speed < _threshold) {
        _thresholdTriggered = false;
      }
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
