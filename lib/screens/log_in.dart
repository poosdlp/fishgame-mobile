import 'package:flutter/material.dart';

import '../widgets/fish_background_screen.dart';
import 'log_in_form.dart';

class LogIn extends StatelessWidget {
  const LogIn({super.key});

  @override
  Widget build(BuildContext context) {
    return const FishBackgroundScreen(
      child: LogInForm(),
    );
  }
}
