import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'auth_service.dart';

class GameSocketService extends ChangeNotifier {
  GameSocketService._();

  static final GameSocketService instance = GameSocketService._();

  WebSocketChannel? _channel;
  Completer<bool>? _readyCompleter;

  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isReady = false;
  String _connectionLabel = 'Disconnected';
  String _gameState = 'unknown';

  final List<String> _events = <String>[];

  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  bool get isReady => _isReady;
  String get connectionLabel => _connectionLabel;
  String get gameState => _gameState;
  List<String> get events => List.unmodifiable(_events);

  Uri _buildWsUri(String token) {
    final base = Uri.parse(AuthService.baseUrl);
    final wsScheme = base.scheme == 'https' ? 'wss' : 'ws';

    return Uri(
      scheme: wsScheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/api/ws',
      queryParameters: <String, String>{'token': token},
    );
  }

  String _timestamp() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _pushEvent(String text) {
    _events.insert(0, '[${_timestamp()}] $text');
    if (_events.length > 50) {
      _events.removeLast();
    }
    notifyListeners();
  }

  Future<bool> connectAndWaitForReady(String token,
      {Duration timeout = const Duration(seconds: 15)}) async {
    if (_isConnected && _isReady) {
      return true;
    }

    if (_isConnecting && _readyCompleter != null) {
      return _waitForReady(_readyCompleter!, timeout);
    }

    if (_isConnected && !_isReady && _readyCompleter != null) {
      return _waitForReady(_readyCompleter!, timeout);
    }

    if (_isConnected && !_isReady && _readyCompleter == null) {
      _readyCompleter = Completer<bool>();
      return _waitForReady(_readyCompleter!, timeout);
    }

    final readyCompleter = Completer<bool>();
    _readyCompleter = readyCompleter;
    final wsUri = _buildWsUri(token);

    _isConnecting = true;
    _isConnected = false;
    _isReady = false;
    _connectionLabel = 'Connecting...';
    _gameState = 'unknown';
    notifyListeners();

    _pushEvent('Connecting to $wsUri');
    debugPrint('WS status: connecting -> $wsUri');

    try {
      final channel = WebSocketChannel.connect(wsUri);
      channel.stream.listen(
            _handleMessage,
            onError: (Object error) {
              _pushEvent('Socket error: $error');
              debugPrint('WS status: error -> $error');
              _finishWithFailure('Socket error');
            },
            onDone: () {
              _pushEvent('Socket closed');
              debugPrint('WS status: closed');
              _finishWithFailure('Disconnected');
            },
          );

      _channel = channel;
      _isConnected = true;
      _connectionLabel = 'Connected';
      _isConnecting = false;
      notifyListeners();

      _pushEvent('Connected. Waiting for ready message.');
      debugPrint('WS status: connected, waiting for ready');

      final ready = await _waitForReady(readyCompleter, timeout);

      debugPrint('WS status: readyFuture resolved -> $ready');

      return ready;
    } catch (error) {
      _pushEvent('Connection failed: $error');
      debugPrint('WS status: connection failed -> $error');
      _finishWithFailure('Connection failed');
      return false;
    }
  }

  Future<bool> _waitForReady(Completer<bool> completer, Duration timeout) {
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _pushEvent('Still waiting for ready message...');
        debugPrint('WS status: still waiting for ready');
        return false;
      },
    );
  }

  Future<bool> connectWithLoginToken({Duration timeout = const Duration(seconds: 15)}) async {
    var token = AuthService.accessToken;
    if (token == null || token.isEmpty) {
      final refreshed = await AuthService().refreshAccessToken();
      token = AuthService.accessToken;
      if (!refreshed || token == null || token.isEmpty) {
        return false;
      }
    }

    return connectAndWaitForReady(token, timeout: timeout);
  }

  void _handleMessage(dynamic raw) {
    final text = raw?.toString() ?? '';
    _pushEvent('IN: $text');

    try {
      final decoded = jsonDecode(text);
      final payload = _extractMessagePayload(decoded);
      if (payload == null) {
        return;
      }

      final type = payload['type']?.toString().toLowerCase();
      final state = payload['state']?.toString().toLowerCase();

      if ((type == 'ready' || (type == null && state != null)) && state != null) {
        _isReady = true;
        _gameState = state;
        _connectionLabel = 'Ready';
        _pushEvent('Ready detected (state=$state).');
        debugPrint('WS status: ready detected, state=$state');
        if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
          _readyCompleter!.complete(true);
        }
        notifyListeners();
        return;
      }

      if (type == 'state' && state != null) {
        _isReady = true;
        _gameState = state;
        debugPrint('WS status: state update -> $state');
        if (_connectionLabel == 'Connected') {
          _connectionLabel = 'Ready';
        }
        if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
          _readyCompleter!.complete(true);
        }
        notifyListeners();
      }
    } catch (_) {
      // Ignore non-JSON payloads.
    }
  }

  Map<String, dynamic>? _extractMessagePayload(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map<String, dynamic>) {
        return decoded['data'] as Map<String, dynamic>;
      }
      if (decoded['payload'] is Map<String, dynamic>) {
        return decoded['payload'] as Map<String, dynamic>;
      }
      if (decoded['message'] is Map<String, dynamic>) {
        return decoded['message'] as Map<String, dynamic>;
      }

      if (decoded['data'] is String) {
        try {
          final nested = jsonDecode(decoded['data'] as String);
          if (nested is Map<String, dynamic>) {
            return nested;
          }
        } catch (_) {}
      }

      return decoded;
    }

    return null;
  }

  void _finishWithFailure(String label) {
    _isConnected = false;
    _isReady = false;
    _isConnecting = false;
    _connectionLabel = label;
    debugPrint('WS status: failure -> $label');
    if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
      _readyCompleter!.complete(false);
    }
    notifyListeners();
  }

  void sendAction(String action) {
    if (!_isConnected || _channel == null) {
      debugPrint('WS status: send skipped (not connected), action=$action');
      return;
    }

    final payload = jsonEncode(<String, String>{'action': action});
    _channel!.sink.add(payload);
    debugPrint('WS status: sent action -> $action');
    _pushEvent('OUT: $payload');
  }

  Future<void> disconnect({bool notify = true}) async {
    debugPrint('WS status: disconnect requested but ignored (only logout may disconnect)');
  }

  Future<void> disconnectOnLogout({bool notify = true}) async {
    debugPrint('WS status: logout disconnect requested');

    final channel = _channel;

    _channel = null;
    _isConnecting = false;
    _isConnected = false;
    _isReady = false;
    _connectionLabel = 'Disconnected';
    _gameState = 'unknown';

    if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
      _readyCompleter!.complete(false);
    }
    _readyCompleter = null;

    if (channel != null) {
      await channel.sink.close();
    }

    if (notify) {
      _pushEvent('Disconnected (logout)');
    } else {
      notifyListeners();
    }

    debugPrint('WS status: disconnected on logout');
  }
}
