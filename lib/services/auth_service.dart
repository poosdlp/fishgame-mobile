import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthResult {
  final bool success;
  final String message;
  final String? accessToken;

  const AuthResult({
    required this.success,
    required this.message,
    this.accessToken,
  });
}

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final uri = _uri('/auth/register');
      final payload = {
        'username': username,
        'email': email,
        'password': password,
      };

      debugPrint('REGISTER url=$uri');
      debugPrint('REGISTER body=${jsonEncode(payload)}');

      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('REGISTER status=${response.statusCode}');
      debugPrint('REGISTER response=${response.body}');

      final data = _decodeBody(response.body);
      final message = data['message']?.toString() ?? 'Unable to create account';

      return AuthResult(
        success: response.statusCode == 201,
        message: message,
      );
    } catch (e, st) {
      debugPrint('REGISTER exception=$e');
      debugPrintStack(stackTrace: st);

      return AuthResult(
        success: false,
        message: 'Could not connect to the backend: $e',
      );
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = _uri('/auth/login');
      final payload = {
        'email': email,
        'password': password,
      };

      debugPrint('LOGIN url=$uri');
      debugPrint('LOGIN body=${jsonEncode(payload)}');

      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('LOGIN status=${response.statusCode}');
      debugPrint('LOGIN response=${response.body}');

      final data = _decodeBody(response.body);
      final accessToken = data['accessToken']?.toString();

      return AuthResult(
        success: response.statusCode == 200 && accessToken != null,
        message: response.statusCode == 200
            ? 'Log in successful'
            : (data['message']?.toString() ?? 'Unable to log in'),
        accessToken: accessToken,
      );
    } catch (e, st) {
      debugPrint('LOGIN exception=$e');
      debugPrintStack(stackTrace: st);

      return AuthResult(
        success: false,
        message: 'Could not connect to the backend: $e',
      );
    }
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return <String, dynamic>{};
  }
}