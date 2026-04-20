import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/auth_service.dart';
import 'accelerometer.dart';

bool truthholder = false;
class ScanCodePage extends StatefulWidget {
  const ScanCodePage({super.key});

  @override
  State<ScanCodePage> createState() => _ScanCodePageState();
}

class _ScanCodePageState extends State<ScanCodePage> {
  String _statusMessage = '';
  bool _isRequesting = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isRequesting) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    final value = barcode!.rawValue!;

    setState(() {
      _statusMessage = '';
      truthholder = true;
      _isRequesting = true;
    });

    final result = await AuthService().approveSession(sessionToken: value);

    if (!mounted) return;

    setState(() {
      _statusMessage = result.message;
      _isRequesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('She pills on my ates'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeedPage()));
            },
            icon: const Icon(Icons.speed),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: _onDetect,
            ),
          ),
          if (_statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

}
