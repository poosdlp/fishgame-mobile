import 'dart:convert';

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
  static const String baseUrl = 'http://10.0.2.2:3000';

  static Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        _uri('/auth/register'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final data = _decodeBody(response.body);
      final message = data['message']?.toString() ?? 'Unable to create account';

      return AuthResult(
        success: response.statusCode == 201,
        message: message,
      );
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Could not connect to the backend',
      );
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        _uri('/auth/login'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = _decodeBody(response.body);
      final accessToken = data['accessToken']?.toString();

      return AuthResult(
        success: response.statusCode == 200 && accessToken != null,
        message: response.statusCode == 200
            ? 'Log in successful'
            : (data['message']?.toString() ?? 'Unable to log in'),
        accessToken: accessToken,
      );
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Could not connect to the backend',
      );
    }
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return <String, dynamic>{};
  }
}
