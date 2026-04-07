import 'package:flutter/material.dart';

import 'screens/game.dart';
import 'screens/license_created.dart';
import 'screens/log_in.dart';
import 'screens/sign_in.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/signup': (context) => const SignUp(),
        '/login': (context) => const LogIn(),
        '/license-created': (context) => const LicenseCreatedScreen(),
        '/game': (context) => const Game(),
      },
    );
  }
}
