import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../widgets/fish_background_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<AuthUser?> _currentUserFuture;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  void _loadSession() {
    _currentUserFuture = _authService.getCurrentUser();
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;

    setState(() {
      _loadSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sw = size.width;
    final sh = size.height;

    final titleStyle = GoogleFonts.pixelifySans(
      fontSize: sw * 0.11,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFFF5F87),
      height: 0.95,
      shadows: const [
        Shadow(color: Color(0x99000000), offset: Offset(3, 3), blurRadius: 0),
      ],
    );

    final messageStyle = GoogleFonts.pixelifySans(
      fontSize: sw * 0.06,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      shadows: const [
        Shadow(color: Color(0x80000000), offset: Offset(2, 2), blurRadius: 0),
      ],
    );

    final usernameStyle = GoogleFonts.pixelifySans(
      fontSize: sw * 0.065,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFFFD54F),
      shadows: const [
        Shadow(color: Color(0xA0000000), offset: Offset(2, 2), blurRadius: 0),
      ],
    );

    final buttonLabelStyle = GoogleFonts.pixelifySans(
      fontSize: sw * 0.05,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    final smallStyle = GoogleFonts.pixelifySans(
      fontSize: sw * 0.032,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    final smallLogoutStyle = GoogleFonts.pixelifySans(
      fontSize: sw * 0.036,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    return FishBackgroundScreen(
      scrollable: false,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sw * 0.08),
          child: Column(
            children: [
              SizedBox(height: sh * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/game'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D4037),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: sw * 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                            color: Colors.orangeAccent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('DEV PLAY', style: smallStyle),
                      ),
                    ),
                  ),
                  FutureBuilder<AuthUser?>(
                    future: _currentUserFuture,
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      if (user == null || user.username.isEmpty) {
                        return const SizedBox(width: 90);
                      }

                      return SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xCC1A237E),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: sw * 0.04),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.white, width: 2),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Log Out', style: smallLogoutStyle),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: sh * 0.1),
              Text(
                'Orlando\nFishing\nAdventure',
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
              SizedBox(height: sh * 0.045),
              Text(
                'Scan the QR code to Play!',
                textAlign: TextAlign.center,
                style: messageStyle,
              ),
              SizedBox(height: sh * 0.1),
              SizedBox(
                width: sw * 0.3,
                height: sw * 0.3,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('Camera/QR scanning not wired up yet.'),
                        ),
                      );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBDBDBD),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Colors.black87, width: 2),
                    ),
                  ),
                  child: Icon(Icons.photo_camera, size: sw * 0.175),
                ),
              ),
              const Spacer(),
              FutureBuilder<AuthUser?>(
                future: _currentUserFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: sh * 0.15),
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: sh * 0.02),
                          Text(
                            'Checking session...',
                            textAlign: TextAlign.center,
                            style: messageStyle,
                          ),
                        ],
                      ),
                    );
                  }

                  final user = snapshot.data;

                  if (user != null && user.username.isNotEmpty) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: sh * 0.15),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: sh * 0.02,
                          horizontal: sw * 0.06,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xAA006064), // soft dark blue
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55000000),
                              offset: Offset(2, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: messageStyle,
                            children: [
                              const TextSpan(text: 'Good luck fishing today '),
                              TextSpan(
                                text: user.username,
                                style: usernameStyle,
                              ),
                              const TextSpan(text: '!'),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _RouteButton(
                              label: 'Sign Up',
                              onPressed: () => Navigator.pushNamed(context, '/signup'),
                              labelStyle: buttonLabelStyle,
                            ),
                          ),
                          SizedBox(width: sw * 0.04),
                          Expanded(
                            child: _RouteButton(
                              label: 'Log In',
                              onPressed: () => Navigator.pushNamed(context, '/login'),
                              labelStyle: buttonLabelStyle,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: sh * 0.15),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteButton extends StatelessWidget {
  const _RouteButton({
    required this.label,
    required this.onPressed,
    required this.labelStyle,
  });

  final String label;
  final VoidCallback onPressed;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xCC1A237E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: labelStyle),
        ),
      ),
    );
  }
}
