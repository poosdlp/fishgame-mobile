import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'auth_service.dart';

class GameSocketService extends ChangeNotifier {
  GameSocketService._();

  static final GameSocketService instance = GameSocketService._();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
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

    await disconnect(notify: false);

    _readyCompleter = Completer<bool>();
    final wsUri = _buildWsUri(token);

    _isConnecting = true;
    _isConnected = false;
    _isReady = false;
    _connectionLabel = 'Connecting...';
    _gameState = 'unknown';
    notifyListeners();

    _pushEvent('Connecting to $wsUri');

    try {
      final channel = WebSocketChannel.connect(wsUri);
      final subscription = channel.stream.listen(
        _handleMessage,
        onError: (Object error) {
          _pushEvent('Socket error: $error');
          _finishWithFailure('Socket error');
        },
        onDone: () {
          _pushEvent('Socket closed');
          _finishWithFailure('Disconnected');
        },
      );

      _channel = channel;
      _subscription = subscription;
      _isConnected = true;
      _connectionLabel = 'Connected';
      _isConnecting = false;
      notifyListeners();

      _pushEvent('Connected. Waiting for ready message.');

      final ready = await _readyCompleter!.future.timeout(
        timeout,
        onTimeout: () {
          _pushEvent('Timed out waiting for ready message.');
          return false;
        },
      );

      if (!ready) {
        await disconnect(notify: false);
      }

      return ready;
    } catch (error) {
      _pushEvent('Connection failed: $error');
      await disconnect(notify: false);
      return false;
    }
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
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final type = decoded['type']?.toString();
      final state = decoded['state']?.toString();

      if (type == 'ready' && state != null) {
        _isReady = true;
        _gameState = state;
        _connectionLabel = 'Ready';
        if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
          _readyCompleter!.complete(true);
        }
        notifyListeners();
        return;
      }

      if (type == 'state' && state != null) {
        _gameState = state;
        notifyListeners();
      }
    } catch (_) {
      // Ignore non-JSON payloads.
    }
  }

  void _finishWithFailure(String label) {
    _isConnected = false;
    _isReady = false;
    _isConnecting = false;
    _connectionLabel = label;
    if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
      _readyCompleter!.complete(false);
    }
    notifyListeners();
  }

  void sendAction(String action) {
    if (!_isConnected || _channel == null) {
      return;
    }

    final payload = jsonEncode(<String, String>{'action': action});
    _channel!.sink.add(payload);
    _pushEvent('OUT: $payload');
  }

  Future<void> disconnect({bool notify = true}) async {
    final subscription = _subscription;
    final channel = _channel;

    _subscription = null;
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

    if (subscription != null) {
      await subscription.cancel();
    }
    if (channel != null) {
      await channel.sink.close();
    }

    if (notify) {
      _pushEvent('Disconnected');
    } else {
      notifyListeners();
    }
  }
}
