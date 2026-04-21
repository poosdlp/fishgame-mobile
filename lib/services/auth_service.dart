import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

class AuthUser {
  final String id;
  final String email;
  final String username;

  const AuthUser({
    required this.id,
    required this.email,
    required this.username,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
    );
  }
}

class AuthService {
  static const String baseUrl = 'http://contacts.0sake.net/api';
  static const String _accessTokenKey = 'auth.accessToken';
  static const String _refreshCookieKey = 'auth.refreshCookie';
  static const String _currentUserKey = 'auth.currentUser';

  static String? _accessToken;
  static String? _refreshCookie;
  static AuthUser? _currentUser;
  static Future<void>? _loadSessionFuture;

  static Uri _uri(String path) => Uri.parse('$baseUrl$path');

  static AuthUser? get currentUser => _currentUser;
  static String? get accessToken => _accessToken;
  static bool get isAuthenticated => _currentUser != null && _accessToken != null;

  static Future<void> _ensureSessionLoaded() {
    _loadSessionFuture ??= _loadSessionFromStorage();
    return _loadSessionFuture!;
  }

  static Future<void> _loadSessionFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    _accessToken = prefs.getString(_accessTokenKey);
    _refreshCookie = prefs.getString(_refreshCookieKey);

    final userRaw = prefs.getString(_currentUserKey);
    if (userRaw == null || userRaw.isEmpty) {
      _currentUser = null;
      return;
    }

    try {
      final userJson = jsonDecode(userRaw);
      if (userJson is Map<String, dynamic>) {
        _currentUser = AuthUser.fromJson(userJson);
        return;
      }
    } catch (_) {}

    _currentUser = null;
  }

  static Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();

    if (_accessToken == null || _accessToken!.isEmpty) {
      await prefs.remove(_accessTokenKey);
    } else {
      await prefs.setString(_accessTokenKey, _accessToken!);
    }

    if (_refreshCookie == null || _refreshCookie!.isEmpty) {
      await prefs.remove(_refreshCookieKey);
    } else {
      await prefs.setString(_refreshCookieKey, _refreshCookie!);
    }

    if (_currentUser == null) {
      await prefs.remove(_currentUserKey);
    } else {
      await prefs.setString(
        _currentUserKey,
        jsonEncode(<String, dynamic>{
          'id': _currentUser!.id,
          'email': _currentUser!.email,
          'username': _currentUser!.username,
        }),
      );
    }
  }

  static Future<void> _clearSession() async {
    _accessToken = null;
    _refreshCookie = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshCookieKey);
    await prefs.remove(_currentUserKey);
  }

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await _ensureSessionLoaded();

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

      if (response.statusCode == 201) {
        return AuthResult(
          success: true,
          message: message,
        );
      }

      return AuthResult(
        success: false,
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
    await _ensureSessionLoaded();

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

      _storeRefreshCookie(response.headers);

      final data = _decodeBody(response.body);
      final accessToken = data['accessToken']?.toString();

      if (response.statusCode == 200 && accessToken != null) {
        _accessToken = accessToken;
        await getCurrentUser();
        await _persistSession();
      }

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

  Future<AuthUser?> getCurrentUser() async {
    await _ensureSessionLoaded();

    if (_accessToken == null) {
      final refreshed = await refreshAccessToken();
      if (!refreshed) return null;
    }

    final response = await http
        .get(
          _uri('/profile/me'),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = _decodeBody(response.body);
      _currentUser = AuthUser.fromJson(data);
      await _persistSession();
      return _currentUser;
    }

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (!refreshed) return null;

      final retryResponse = await http
          .get(
            _uri('/auth/me'),
            headers: _authHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (retryResponse.statusCode == 200) {
        final data = _decodeBody(retryResponse.body);
        _currentUser = AuthUser.fromJson(data);
        await _persistSession();
        return _currentUser;
      }
    }

    return null;
  }

  Future<AuthResult> approveSession({required String sessionToken}) async {
    await _ensureSessionLoaded();

    if (_accessToken == null) {
      final refreshed = await refreshAccessToken();
      if (!refreshed) {
        return const AuthResult(
          success: false,
          message: 'You must log in before approving a session.',
        );
      }
    }

    try {
      final response = await http
          .post(
            _uri('/session/$sessionToken/approve'),
            headers: _authHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      final data = _decodeBody(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AuthResult(
          success: true,
          message: data['message']?.toString() ?? 'QR request sent successfully.',
        );
      }

      return AuthResult(
        success: false,
        message: data['message']?.toString() ?? 'QR request failed (${response.statusCode}).',
      );
    } catch (e, st) {
      debugPrint('APPROVE SESSION exception=$e');
      debugPrintStack(stackTrace: st);

      return AuthResult(
        success: false,
        message: 'Could not send QR request: $e',
      );
    }
  }

  Future<AuthResult> pollSessionAccessToken({
    required String sessionToken,
    int maxAttempts = 15,
    Duration interval = const Duration(seconds: 1),
  }) async {
    await _ensureSessionLoaded();

    if (_accessToken == null) {
      final refreshed = await refreshAccessToken();
      if (!refreshed) {
        return const AuthResult(
          success: false,
          message: 'You must log in before polling session status.',
        );
      }
    }

    for (var i = 0; i < maxAttempts; i++) {
      try {
        final response = await http
            .get(
              _uri('/session/$sessionToken/status'),
              headers: _authHeaders(),
            )
            .timeout(const Duration(seconds: 10));

        final data = _decodeBody(response.body);
        final status = data['status']?.toString().toLowerCase() ?? '';
        final accessToken = data['accessToken']?.toString();

        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (status == 'approved' && accessToken != null && accessToken.isNotEmpty) {
            return AuthResult(
              success: true,
              message: 'Session approved.',
              accessToken: accessToken,
            );
          }

          if (status == 'denied' || status == 'rejected' || status == 'expired') {
            return AuthResult(
              success: false,
              message: 'Session is $status.',
            );
          }
        } else {
          return AuthResult(
            success: false,
            message: data['message']?.toString() ?? 'Failed to poll session status.',
          );
        }
      } catch (e, st) {
        debugPrint('POLL SESSION exception=$e');
        debugPrintStack(stackTrace: st);

        return AuthResult(
          success: false,
          message: 'Could not poll session status: $e',
        );
      }

      if (i < maxAttempts - 1) {
        await Future<void>.delayed(interval);
      }
    }

    return const AuthResult(
      success: false,
      message: 'Timed out waiting for session approval.',
    );
  }

  Future<bool> refreshAccessToken() async {
    await _ensureSessionLoaded();

    if (_refreshCookie == null) {
      return false;
    }

    try {
      final response = await http
          .post(
            _uri('/auth/refresh'),
            headers: {
              'Content-Type': 'application/json',
              'Cookie': _refreshCookie!,
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('REFRESH status=${response.statusCode}');
      debugPrint('REFRESH response=${response.body}');

      _storeRefreshCookie(response.headers);

      if (response.statusCode != 200) {
        return false;
      }

      final data = _decodeBody(response.body);
      final accessToken = data['accessToken']?.toString();

      if (accessToken == null || accessToken.isEmpty) {
        return false;
      }

      _accessToken = accessToken;
      await _persistSession();
      return true;
    } catch (e, st) {
      debugPrint('REFRESH exception=$e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  Future<AuthResult> logout() async {
    await _ensureSessionLoaded();

    try {
      final response = await http
          .post(
            _uri('/auth/logout'),
            headers: _authHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('LOGOUT status=${response.statusCode}');
      debugPrint('LOGOUT response=${response.body}');

      await _clearSession();

      if (response.statusCode == 200) {
        final data = _decodeBody(response.body);
        return AuthResult(
          success: true,
          message: data['message']?.toString() ?? 'Logged out',
        );
      }

      final data = _decodeBody(response.body);
      return AuthResult(
        success: false,
        message: data['message']?.toString() ?? 'Unable to log out',
      );
    } catch (e, st) {
      debugPrint('LOGOUT exception=$e');
      debugPrintStack(stackTrace: st);

      await _clearSession();

      return AuthResult(
        success: false,
        message: 'Could not connect to the backend: $e',
      );
    }
  }

  Future<AuthResult> deleteAccount() async {
    await _ensureSessionLoaded();

    try {
      final response = await http
          .delete(
            _uri('/profile/me'),
            headers: _authHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('DELETE ACCOUNT status=${response.statusCode}');
      debugPrint('DELETE ACCOUNT response=${response.body}');

      final data = _decodeBody(response.body);
      final message = data['message']?.toString() ?? 'Account deleted';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AuthResult(
          success: true,
          message: message,
        );
      }

      return AuthResult(
        success: false,
        message: message,
      );
    } catch (e, st) {
      debugPrint('DELETE ACCOUNT exception=$e');
      debugPrintStack(stackTrace: st);

      return AuthResult(
        success: false,
        message: 'Could not delete account: $e',
      );
    }
  }

  static Map<String, String> _authHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    if (_refreshCookie != null) {
      headers['Cookie'] = _refreshCookie!;
    }

    return headers;
  }

  static void _storeRefreshCookie(Map<String, String> headers) {
    String? setCookie;

    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'set-cookie') {
        setCookie = entry.value;
        break;
      }
    }

    if (setCookie == null || setCookie.isEmpty) return;

    final firstPart = setCookie.split(';').first.trim();
    if (firstPart.contains('=')) {
      _refreshCookie = firstPart;
      debugPrint('Stored refresh cookie=$_refreshCookie');
      _persistSession();
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
