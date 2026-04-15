import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'accelerometer.dart';

bool truthholder = false;
class ScanCodePage extends StatefulWidget {
  const ScanCodePage({super.key});

  @override
  State<ScanCodePage> createState() => _ScanCodePageState();
}

// DotEnv dotenv = DotEnv() is automatically called during import.
// If you want to load multiple dotenv files or name your dotenv object differently, you can do the following and import the singleton into the relavant files:
// DotEnv another_dotenv = DotEnv()


class _ScanCodePageState extends State<ScanCodePage> {
  String _scannedValue = '';
  String urlString = '';

  void _onDetect(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    final value = barcode!.rawValue!;
    setState(() {
      _scannedValue = value;
      final baseUrl = dotenv.env['BASE_URL'];
      //http://{{baseurl}}/api/session/{{sessionToken}}/approve
      if(_scannedValue != '' && baseUrl != ''){
      urlString = "http://$baseUrl/api/session/$_scannedValue/approve";
      truthholder = true;
      } else {
       Text('Speed threshold reached :D');
      }
    });
   

    if(_scannedValue != ''){
      launchUrlString(urlString, mode: LaunchMode.externalApplication);
    }else{ 
      Text('Error pulling sessionToken');
    }
    
     
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
        ],
      ),
    );
  }

  Future<bool> urllauncher() => launchUrlString(urlString);
  

}
