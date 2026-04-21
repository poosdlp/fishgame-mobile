import 'package:flutter_test/flutter_test.dart';
import 'package:fishgame_mobile/services/auth_service.dart';

void main() {

    print("Running tests on auth_service.dart");

  group('AuthUser.fromJson', () {
    test('creates AuthUser from valid string fields', () {
      final json = {
        'id': '123',
        'email': 'test@example.com',
        'username': 'Marcus',
      };

      final user = AuthUser.fromJson(json);

      expect(user.id, '123');
      expect(user.email, 'test@example.com');
      expect(user.username, 'Marcus');
    });

    test('converts numeric id to string', () {
      final json = {
        'id': 123,
        'email': 'test@example.com',
        'username': 'Marcus',
      };

      final user = AuthUser.fromJson(json);

      expect(user.id, '123');
      expect(user.email, 'test@example.com');
      expect(user.username, 'Marcus');
    });

    test('returns empty strings when fields are missing', () {
      final json = <String, dynamic>{};

      final user = AuthUser.fromJson(json);

      expect(user.id, '');
      expect(user.email, '');
      expect(user.username, '');
    });

    test('returns empty strings when fields are null', () {
      final json = {
        'id': null,
        'email': null,
        'username': null,
      };

      final user = AuthUser.fromJson(json);

      expect(user.id, '');
      expect(user.email, '');
      expect(user.username, '');
    });

    test('converts non-string email and username values using toString', () {
      final json = {
        'id': 999,
        'email': 42,
        'username': true,
      };

      final user = AuthUser.fromJson(json);

      expect(user.id, '999');
      expect(user.email, '42');
      expect(user.username, 'true');
    });

    test('handles mixed missing and present fields', () {
      final json = {
        'email': 'partial@example.com',
      };

      final user = AuthUser.fromJson(json);

      expect(user.id, '');
      expect(user.email, 'partial@example.com');
      expect(user.username, '');
    });
  });
}