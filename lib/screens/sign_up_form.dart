import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/pixel_input.dart';
import '../services/auth_service.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
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

    final result = await _authService.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (!result.success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      return;
    }

    Navigator.pushReplacementNamed(context, '/license-created');
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
            Padding(
              padding: EdgeInsets.only(
                left: sw * 0.1,
                right: sw * 0.1,
                top: sh * 0.1,
              ),
              child: Text(
                'Username',
                style: labelStyle,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.1),
              child: PixelInput(
                controller: _usernameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a username';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: sw * 0.1,
                right: sw * 0.1,
                top: sh * 0.05,
              ),
              child: Text(
                'Email',
                style: labelStyle,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.1),
              child: PixelInput(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an email';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: sw * 0.1,
                right: sw * 0.1,
                top: sh * 0.05,
              ),
              child: Text(
                'Password',
                style: labelStyle,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.1),
              child: PixelInput(
                controller: _passwordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a password';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: sh * 0.08,
                left: sw * 0.1,
                right: sw * 0.1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}