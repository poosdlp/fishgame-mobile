import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:fishgame_mobile/main.dart' as app;

const String _testEmail = String.fromEnvironment('TEST_EMAIL');
const String _testPassword = String.fromEnvironment('TEST_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('real backend auth flow', () {
    testWidgets('logs in against the deployed server and shows logged-in home UI', (
      WidgetTester tester,
    ) async {
      _assertCredentialsProvided();

      app.main();
      await tester.pumpAndSettle();

      await _ensureLoggedOutHome(tester);
      await _openLoginScreen(tester);
      await _login(tester, email: _testEmail, password: _testPassword);

      await _pumpUntilFound(
        tester,
        find.textContaining('Good luck fishing today'),
        timeout: const Duration(seconds: 20),
      );

      expect(find.text('Log Out'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.text('PASTE QR'), findsOneWidget);
      expect(find.text('Scan the QR code to Play!'), findsOneWidget);
      expect(find.text('Sign Up'), findsNothing);
      expect(find.text('Log In'), findsNothing);
    });

    testWidgets('logs out and returns to the logged-out home screen', (
      WidgetTester tester,
    ) async {
      _assertCredentialsProvided();

      app.main();
      await tester.pumpAndSettle();

      await _ensureLoggedInHome(
        tester,
        email: _testEmail,
        password: _testPassword,
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log Out'));
      await tester.pump();

      await _pumpUntilFound(
        tester,
        find.widgetWithText(ElevatedButton, 'Log In'),
        timeout: const Duration(seconds: 20),
      );

      expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);
      expect(find.textContaining('Good luck fishing today'), findsNothing);
      expect(find.text('Log Out'), findsNothing);
      expect(find.text('Delete Account'), findsNothing);
    });
  });
}

void _assertCredentialsProvided() {
  assert(
    _testEmail.isNotEmpty && _testPassword.isNotEmpty,
    'Missing TEST_EMAIL or TEST_PASSWORD. Run with '
    '--dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...',
  );

  if (_testEmail.isEmpty || _testPassword.isEmpty) {
    throw StateError(
      'Missing TEST_EMAIL or TEST_PASSWORD. Run with '
      '--dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...',
    );
  }
}

Future<void> _ensureLoggedOutHome(WidgetTester tester) async {
  await _dismissAnyTransientUi(tester);

  if (find.widgetWithText(ElevatedButton, 'Log Out').evaluate().isNotEmpty) {
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log Out'));
    await tester.pump();
  }

  await _pumpUntilFound(
    tester,
    find.widgetWithText(ElevatedButton, 'Log In'),
    timeout: const Duration(seconds: 20),
  );
}

Future<void> _ensureLoggedInHome(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await _dismissAnyTransientUi(tester);

  if (find.textContaining('Good luck fishing today').evaluate().isNotEmpty) {
    return;
  }

  await _ensureLoggedOutHome(tester);
  await _openLoginScreen(tester);
  await _login(tester, email: email, password: password);

  await _pumpUntilFound(
    tester,
    find.textContaining('Good luck fishing today'),
    timeout: const Duration(seconds: 20),
  );
}

Future<void> _openLoginScreen(WidgetTester tester) async {
  await _pumpUntilFound(
    tester,
    find.widgetWithText(ElevatedButton, 'Log In'),
    timeout: const Duration(seconds: 20),
  );

  await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
  await tester.pumpAndSettle();

  await _pumpUntilFound(
    tester,
    find.text('Forgot Password'),
    timeout: const Duration(seconds: 10),
  );
}

Future<void> _login(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  final emailField = find.byType(TextFormField).at(0);
  final passwordField = find.byType(TextFormField).at(1);

  await _pumpUntilFound(
    tester,
    emailField,
    timeout: const Duration(seconds: 10),
  );

  await tester.enterText(emailField, email);
  await tester.enterText(passwordField, password);

  await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
  await tester.pump();

  await _pumpUntilFound(
    tester,
    find.byType(CircularProgressIndicator),
    timeout: const Duration(seconds: 5),
    optional: true,
  );
}

Future<void> _dismissAnyTransientUi(WidgetTester tester) async {
  if (find.text('OK').evaluate().isNotEmpty) {
    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();
  }
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
  bool optional = false,
}) async {
  final end = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  if (optional) {
    return;
  }

  throw TestFailure('Timed out waiting for finder: $finder');
}