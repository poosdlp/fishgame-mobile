import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/fish_background_screen.dart';

class LicenseCreatedScreen extends StatefulWidget {
  const LicenseCreatedScreen({super.key});

  @override
  State<LicenseCreatedScreen> createState() => _LicenseCreatedScreenState();
}

class _LicenseCreatedScreenState extends State<LicenseCreatedScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sw = size.width;
    final sh = size.height;

    final titleStyle = GoogleFonts.pixelifySans(
      fontSize: 34,
      color: const Color.fromARGB(255, 255, 182, 64),
      shadows: const [Shadow(color: Colors.black38, offset: Offset(2, 2))],
    );

    return FishBackgroundScreen(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.1),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                border: Border.all(
                  color: const Color.fromARGB(255, 143, 97, 28),
                  width: 4,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fishing license\ncreated!',
                    textAlign: TextAlign.center,
                    style: titleStyle,
                  ),
                  SizedBox(height: sh * 0.03),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    },
                    child: const Text('Back to Home Screen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
