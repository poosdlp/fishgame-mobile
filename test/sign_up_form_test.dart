import 'package:flutter_test/flutter_test.dart';
import 'package:fishgame_mobile/screens/sign_up_form.dart';

void main() {

  print("Running tests on sign_up_form.dart");

  group('isValidEmail', () {
    test('returns true for a valid email', () {
      expect(isValidEmail('test@example.com'), isTrue);
    });

    test('returns true for a valid email with surrounding whitespace', () {
      expect(isValidEmail('  test@example.com  '), isTrue);
    });

    test('returns false when missing @ symbol', () {
      expect(isValidEmail('testexample.com'), isFalse);
    });

    test('returns false when missing domain name', () {
      expect(isValidEmail('test@.com'), isFalse);
    });

    test('returns false when missing top-level domain', () {
      expect(isValidEmail('test@example'), isFalse);
    });

    test('returns false for an empty string', () {
      expect(isValidEmail(''), isFalse);
    });
  });

  group('isValidUsername', () {
    test('returns true for letters only', () {
      expect(isValidUsername('Marcus'), isTrue);
    });

    test('returns true for letters, numbers, and underscores', () {
      expect(isValidUsername('Marcus_123'), isTrue);
    });

    test('returns true for numbers only', () {
      expect(isValidUsername('12345'), isTrue);
    });

    test('returns false when username contains spaces', () {
      expect(isValidUsername('Marcus Smith'), isFalse);
    });

    test('returns false when username contains punctuation', () {
      expect(isValidUsername('Marcus!'), isFalse);
    });

    test('returns false when username contains a hyphen', () {
      expect(isValidUsername('Marcus-S'), isFalse);
    });

    test('returns false for an empty string', () {
      expect(isValidUsername(''), isFalse);
    });
  });
}