import 'package:flutter/material.dart';

import '../widgets/fish_background_screen.dart';
import 'sign_up_form.dart';

class SignUp extends StatelessWidget {
  const SignUp({super.key});

  @override
  Widget build(BuildContext context) {
    return const FishBackgroundScreen(
      child: SignUpForm(),
    );
  }
}
