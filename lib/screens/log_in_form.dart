import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../widgets/auth_form_buttons.dart';
import '../widgets/labeled_pixel_input.dart';

class LogInForm extends StatefulWidget {
  const LogInForm({super.key});

  @override
  State<LogInForm> createState() => _LogInFormState();
}

class _LogInFormState extends State<LogInForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isSubmitting = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(trimmed);
  }

  bool _validateFields() {
    bool valid = true;

    setState(() {
      _emailError = null;
      _passwordError = null;

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty) {
        _emailError = 'Enter an email';
        valid = false;
      } else if (!_isValidEmail(email)) {
        _emailError = 'Enter a valid email';
        valid = false;
      }

      if (password.isEmpty) {
        _passwordError = 'Enter a password';
        valid = false;
      }
    });

    return valid;
  }

  Future<void> _showDialog(String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_validateFields()) return;

    setState(() => _isSubmitting = true);

    final result = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result.success) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    final msg = result.message.toLowerCase();

    if (msg.contains('invalid credentials')) {
      setState(() {
        _passwordError = 'Invalid email or password';
      });
      return;
    }

    if (msg.contains('verify your email')) {
      await _showDialog('Please verify your email before logging in.');
      return;
    }

    await _showDialog(result.message);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sw = size.width;
    final sh = size.height;

    final titleStyle = GoogleFonts.pixelifySans(
      fontSize: 40,
      color: const Color.fromARGB(255, 255, 182, 64),
      shadows: const [
        Shadow(
          color: Colors.black38,
          offset: Offset(2, 2),
        ),
      ],
    );

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: sh * 0.08,
              left: sw * 0.1,
              right: sw * 0.1,
            ),
            child: Text('LOG IN', style: titleStyle),
          ),
          LabeledPixelInput(
            label: 'Email',
            controller: _emailController,
            sw: sw,
            topPadding: sh * 0.1,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
            onChanged: (_) {
              if (_emailError != null) {
                setState(() => _emailError = null);
              }
            },
          ),
          LabeledPixelInput(
            label: 'Password',
            controller: _passwordController,
            sw: sw,
            topPadding: sh * 0.05,
            obscureText: true,
            errorText: _passwordError,
            onChanged: (_) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
          ),
          AuthFormButtons(
            sh: sh,
            sw: sw,
            isSubmitting: _isSubmitting,
            onBack: () => Navigator.pop(context),
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}
