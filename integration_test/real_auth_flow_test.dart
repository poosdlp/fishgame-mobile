import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:fishgame_mobile/main.dart' as app;

const String _testEmail = String.fromEnvironment('TEST_EMAIL');
const String _testPassword = String.fromEnvironment('TEST_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('real backend auth flow', () {
    testWidgets('logs in against deployed backend', (tester) async {
      _assertCredentialsProvided();

      _logStep('launching app');
      app.main();
      await _pumpFor(tester, const Duration(seconds: 2));

      await _ensureLoggedOutHome(tester);

      _logStep('opening login screen');
      await _openLoginScreen(tester);

      _logStep('submitting real credentials');
      await _login(
        tester,
        email: _testEmail,
        password: _testPassword,
      );

      _logStep('waiting for authenticated home');
      await _pumpUntilFound(
        tester,
        find.widgetWithText(ElevatedButton, 'Log Out'),
        timeout: const Duration(seconds: 25),
        description: 'authenticated home screen',
      );

      expect(find.widgetWithText(ElevatedButton, 'Log Out'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Delete Account'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Log In'), findsNothing);
    });

    testWidgets('logs out back to public home', (tester) async {
      _assertCredentialsProvided();

      _logStep('launching app');
      app.main();
      await _pumpFor(tester, const Duration(seconds: 2));

      await _ensureLoggedInHome(
        tester,
        email: _testEmail,
        password: _testPassword,
      );

      _logStep('tapping logout');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log Out'));
      await tester.pump();

      await _pumpUntilFound(
        tester,
        find.widgetWithText(ElevatedButton, 'Log In'),
        timeout: const Duration(seconds: 25),
        description: 'public home after logout',
      );

      expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Log Out'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Delete Account'), findsNothing);
    });

    testWidgets('shows validation error for bad credentials', (tester) async {
      _logStep('launching app');
      app.main();
      await _pumpFor(tester, const Duration(seconds: 2));

      await _ensureLoggedOutHome(tester);
      await _openLoginScreen(tester);

      _logStep('submitting invalid credentials');
      await _login(
        tester,
        email: 'definitely-not-a-real-user@example.com',
        password: 'wrongpassword123',
      );

      await _pumpUntilFound(
        tester,
        find.text('Invalid email or password'),
        timeout: const Duration(seconds: 20),
        description: 'invalid login error',
      );

      expect(find.text('Invalid email or password'), findsOneWidget);
    });
  });
}

void _assertCredentialsProvided() {
  assert(
    _testEmail.isNotEmpty && _testPassword.isNotEmpty,
    'Missing TEST_EMAIL or TEST_PASSWORD. '
    'Run with --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...',
  );

  if (_testEmail.isEmpty || _testPassword.isEmpty) {
    throw StateError(
      'Missing TEST_EMAIL or TEST_PASSWORD. '
      'Run with --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...',
    );
  }
}

Future<void> _ensureLoggedOutHome(WidgetTester tester) async {
  _logStep('ensuring logged-out home');

  await _dismissDialogsIfPresent(tester);

  if (find.widgetWithText(ElevatedButton, 'Log Out').evaluate().isNotEmpty) {
    _logStep('app already logged in, logging out first');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log Out'));
    await tester.pump();
  }

  // If we're on login screen instead of home, go back.
  if (find.widgetWithText(ElevatedButton, 'Back').evaluate().isNotEmpty) {
    _logStep('login screen detected, navigating back home');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Back'));
    await tester.pump();
  }

  await _pumpUntilFound(
    tester,
    find.widgetWithText(ElevatedButton, 'Log In'),
    timeout: const Duration(seconds: 25),
    description: 'logged-out home screen',
  );
}

Future<void> _ensureLoggedInHome(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  _logStep('ensuring logged-in home');

  await _dismissDialogsIfPresent(tester);

  if (find.widgetWithText(ElevatedButton, 'Log Out').evaluate().isNotEmpty) {
    _logStep('already authenticated');
    return;
  }

  await _ensureLoggedOutHome(tester);
  await _openLoginScreen(tester);
  await _login(tester, email: email, password: password);

  await _pumpUntilFound(
    tester,
    find.widgetWithText(ElevatedButton, 'Log Out'),
    timeout: const Duration(seconds: 25),
    description: 'logged-in home screen',
  );
}

Future<void> _openLoginScreen(WidgetTester tester) async {
  await _pumpUntilFound(
    tester,
    find.widgetWithText(ElevatedButton, 'Log In'),
    timeout: const Duration(seconds: 20),
    description: 'Log In button on home',
  );

  await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
  await tester.pump();

  await _pumpUntilFound(
    tester,
    find.text('Forgot Password'),
    timeout: const Duration(seconds: 15),
    description: 'login form',
  );
}

Future<void> _login(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  final textFields = find.byType(TextFormField);

  await _pumpUntilFound(
    tester,
    textFields,
    timeout: const Duration(seconds: 15),
    description: 'email/password fields',
  );

  expect(textFields, findsAtLeastNWidgets(2));

  await tester.enterText(textFields.at(0), email);
  await tester.enterText(textFields.at(1), password);

  await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
  await tester.pump();

  // Give the network request a chance to start and navigation a chance to happen.
  await _pumpFor(tester, const Duration(seconds: 2));
}

Future<void> _dismissDialogsIfPresent(WidgetTester tester) async {
  if (find.text('OK').evaluate().isNotEmpty) {
    _logStep('dismissing dialog');
    await tester.tap(find.text('OK').last);
    await tester.pump();
  }
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
  required String description,
}) async {
  final deadline = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));

    if (finder.evaluate().isNotEmpty) {
      _logStep('found $description');
      return;
    }
  }

  _logStep('timed out waiting for $description');
  debugDumpApp();
  throw TestFailure('Timed out waiting for $description');
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _logStep(String message) {
  // ignore: avoid_print
  print('[real_auth_flow_test] $message');
}