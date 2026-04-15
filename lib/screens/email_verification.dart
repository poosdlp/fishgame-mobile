import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/fish_background_screen.dart';

class EmailVerification extends StatefulWidget {
  const EmailVerification({
    super.key,
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  final AuthService _authService = AuthService();

  Timer? _pollTimer;
  bool _isChecking = false;
  bool _manualCheckInProgress = false;
  String? _statusMessage;

  static const String _verificationMessage =
      'Sign up form completed! Please verify your email to finish the account creation process. On verification you will be redirected to the home page so your fishing adventure can begin!';

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _attemptLogin(showPendingMessage: false),
    );
  }

  Future<void> _attemptLogin({required bool showPendingMessage}) async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      if (showPendingMessage) {
        _manualCheckInProgress = true;
        _statusMessage = 'Checking your verification status...';
      }
    });

    final result = await _authService.login(
      email: widget.email,
      password: widget.password,
    );

    if (!mounted) return;

    if (result.success) {
      _pollTimer?.cancel();
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      return;
    }

    final message = result.message.toLowerCase();

    setState(() {
      _isChecking = false;
      _manualCheckInProgress = false;

      if (showPendingMessage) {
        if (message.contains('verify your email')) {
          _statusMessage = 'Your email is not verified yet. Please click the verification link in your inbox and try again.';
        } else {
          _statusMessage = result.message;
        }
      }
    });
  }

  void _goBackToHome() {
    _pollTimer?.cancel();
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final sw = size.width;
    final sh = size.height;

    return FishBackgroundScreen(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: sw * 0.08,
            vertical: sh * 0.08,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4EC),
                    border: Border.all(
                      color: const Color(0xFFE78FB3),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    _verificationMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (_statusMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isChecking
                        ? null
                        : () => _attemptLogin(showPendingMessage: true),
                    child: Text(
                      _manualCheckInProgress
                          ? 'Checking...'
                          : 'I verified my email',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _goBackToHome,
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
