import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../widgets/auth_form_buttons.dart';
import '../widgets/labeled_pixel_input.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isSubmitting = false;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(trimmed);
  }

  bool _isValidUsername(String username) {
    final usernameRegex = RegExp(r'^[A-Za-z0-9_]+$');
    return usernameRegex.hasMatch(username);
  }

  bool _validateFields() {
    bool isValid = true;

    setState(() {
      _usernameError = null;
      _emailError = null;
      _passwordError = null;

      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (username.isEmpty) {
        _usernameError = 'Username is required';
        isValid = false;
      } else if (username.length < 3) {
        _usernameError = 'Username must be at least 3 characters';
        isValid = false;
      } else if (username.length > 20) {
        _usernameError = 'Username must be 20 characters or less';
        isValid = false;
      } else if (!_isValidUsername(username)) {
        _usernameError = 'Use only letters, numbers, and underscores';
        isValid = false;
      }

      if (email.isEmpty) {
        _emailError = 'Email is required';
        isValid = false;
      } else if (!_isValidEmail(email)) {
        _emailError = 'Enter a valid email';
        isValid = false;
      }

      if (password.isEmpty) {
        _passwordError = 'Password is required';
        isValid = false;
      } else if (password.length < 8) {
        _passwordError = 'Password must be at least 8 characters';
        isValid = false;
      } else if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
        _passwordError = 'Password must include at least 1 letter';
        isValid = false;
      } else if (!RegExp(r'\d').hasMatch(password)) {
        _passwordError = 'Password must include at least 1 number';
        isValid = false;
      }
    });

    return isValid;
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Up Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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

    final result = await _authService.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result.success) {
      Navigator.pushReplacementNamed(context, '/license-created');
      return;
    }

    final normalizedMessage = result.message.toLowerCase();

    if (normalizedMessage.contains('user already exists')) {
      setState(() {
        _emailError = 'An account with this email already exists';
      });
      return;
    }

    if (normalizedMessage.contains('username')) {
      setState(() {
        _usernameError = result.message;
      });
      return;
    }

    if (normalizedMessage.contains('email')) {
      setState(() {
        _emailError = result.message;
      });
      return;
    }

    if (normalizedMessage.contains('password')) {
      setState(() {
        _passwordError = result.message;
      });
      return;
    }

    await _showErrorDialog(result.message);
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
            child: Text(
              'GET YOUR\nFISHING LICENSE',
              style: titleStyle,
            ),
          ),
          LabeledPixelInput(
            label: 'Username',
            controller: _usernameController,
            sw: sw,
            topPadding: sh * 0.1,
            errorText: _usernameError,
            onChanged: (_) {
              if (_usernameError != null) {
                setState(() => _usernameError = null);
              }
            },
          ),
          LabeledPixelInput(
            label: 'Email',
            controller: _emailController,
            sw: sw,
            topPadding: sh * 0.05,
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
