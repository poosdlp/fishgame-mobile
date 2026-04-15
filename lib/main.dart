import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/game.dart';
import 'screens/license_created.dart';
import 'screens/home.dart';
import 'screens/log_in.dart';
import 'screens/sign_up.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
      routes: {
        '/home': (context) => const Home(),
        '/signup': (context) => const SignUp(),
        '/login': (context) => const LogIn(),
        '/license-created': (context) => const LicenseCreatedScreen(),
        '/game': (context) => const Game(),
      },
    );
  }
}
