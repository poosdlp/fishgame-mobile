import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../widgets/water_scene.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          WaterSceneBackground(animation: _controller),
          const SafeArea(
            child: SingleChildScrollView(
              child: _LogInForm(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogInForm extends StatefulWidget {
  const _LogInForm();

  @override
  State<_LogInForm> createState() => _LogInFormState();
}

class _LogInFormState extends State<_LogInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.message),
          duration: const Duration(seconds: 2),
        ),
      );

    if (result.success) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/game');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sw = size.width;
    final sh = size.height;

    final titleStyle = GoogleFonts.pixelifySans(
      fontSize: 40,
      color: const Color.fromARGB(255, 254, 110, 94),
      shadows: const [Shadow(color: Colors.black38, offset: Offset(2, 2))],
    );

    final labelStyle = GoogleFonts.pixelifySans(
      color: Colors.black,
      fontSize: 32,
    );

    return Form(
      key: _formKey,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: sh * 0.08, left: sw * 0.1, right: sw * 0.1),
              child: Text('Log In', style: titleStyle),
            ),
            Padding(
              padding: EdgeInsets.only(left: sw * 0.1, right: sw * 0.1, top: sh * 0.1),
              child: Text('Email', style: labelStyle),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.1),
              child: PixelInput(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter your email';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: sw * 0.1, right: sw * 0.1, top: sh * 0.05),
              child: Text('Password', style: labelStyle),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.1),
              child: PixelInput(
                controller: _passwordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your password';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: sh * 0.06, left: sw * 0.1, right: sw * 0.1),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text(
                    'New fisherman? Get your license',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PixelInput extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  const PixelInput({
    super.key,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.pixelifySans(fontSize: 16, color: Colors.black);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(3),
      color: const Color.fromARGB(255, 143, 97, 28),
      child: Container(
        padding: const EdgeInsets.all(3),
        color: const Color.fromARGB(255, 120, 85, 50),
        child: Container(
          color: const Color.fromARGB(235, 255, 255, 255),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: textStyle,
            validator: validator,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
          ),
        ),
      ),
    );
  }
}
