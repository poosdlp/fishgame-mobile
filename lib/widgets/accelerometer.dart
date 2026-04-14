import 'dart:math';
import 'dart:ui';
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
  int counter = 0;
  int temp_count = 0;
  int _test_scale = 0;
  int temp_test_scale = 0;

  static const double _threshold = 10.0;
  static const double _good_throw_threshold = 12.0;
  static const double _great_throw_threshold = 16.0;
  static const double _amazing_throw_threshold = 20.0;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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

      if (speed >= _amazing_throw_threshold && _test_scale < 4) {
  
        _showMessage('Amazing throw 4');
        counter++;
        _test_scale = 4;
        
      } else if (speed >= _great_throw_threshold && _test_scale < 3) {
   
        _showMessage('Great throw 3');
        counter++;
       _test_scale= 3;
      } else if (speed >= _good_throw_threshold && _test_scale < 2) {
     
        _showMessage('Good throw 2');
        counter++;
        _test_scale = 2;
      } else if (speed >= _threshold && _test_scale < 1) {
        _showMessage('Speed threshold reached 1');
        counter++;
       _test_scale = 1;
      } else if (speed < _threshold) {
        if(counter >= temp_count){
          temp_count = counter;
          counter = 0;
        }
      
      _test_scale = 0;
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
          
          children: [
          Text(
            _speed.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 96,
              color: Colors.black,
            ),
          ),
          Text(
            'Counter $temp_count',
              style: const TextStyle(
              fontSize: 36,
              color: Colors.black,
              ),
            ),
          Text(
            'scale $_test_scale',
              style: const TextStyle(
              fontSize: 36,
              color: Colors.black,
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
