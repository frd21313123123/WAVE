import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/io.dart';

import '../config/app_config.dart';
import 'api_client.dart';

class RealtimeService {
  RealtimeService({
    required this.apiClient,
    required this.appConfig,
  }) {
    appConfig.addListener(_handleConfigChanged);
  }

  final ApiClient apiClient;
  final AppConfig appConfig;

  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();
  final List<Map<String, dynamic>> _pendingPayloads = <Map<String, dynamic>>[];

  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _activeSession = false;
  bool _isConnecting = false;
  int _reconnectAttempt = 0;

  Stream<Map<String, dynamic>> get events => _events.stream;

  Future<void> activate() async {
    _activeSession = true;
    await _connect();
  }

  Future<void> deactivate() async {
    _activeSession = false;
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _pendingPayloads.clear();
    _isConnecting = false;
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }

  Future<void> send(Map<String, dynamic> payload) async {
    if (_channel == null) {
      if (_activeSession) {
        _enqueuePayload(payload);
      }
      return;
    }

    try {
      _channel!.sink.add(jsonEncode(payload));
    } catch (_) {
      if (_activeSession) {
        _enqueuePayload(payload);
        _scheduleReconnect();
      }
    }
  }

  Future<void> _connect() async {
    if (!_activeSession || _channel != null || _isConnecting) {
      return;
    }
    _isConnecting = true;

    final cookieHeader = await apiClient.cookieHeader();
    final headers = <String, dynamic>{};
    if (cookieHeader.isNotEmpty) {
      headers[HttpHeaders.cookieHeader] = cookieHeader;
    }

    late final IOWebSocketChannel channel;
    try {
      channel = IOWebSocketChannel.connect(
        appConfig.wsUri,
        headers: headers.isEmpty ? null : headers,
      );
    } catch (_) {
      _isConnecting = false;
      _scheduleReconnect();
      return;
    }
    _channel = channel;
    _isConnecting = false;

    _subscription = channel.stream.listen(
      (dynamic data) {
        _reconnectAttempt = 0;
        final raw = data is String ? data : data.toString();
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            _events.add(decoded);
          } else if (decoded is Map) {
            _events.add(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {
          return;
        }
      },
      onError: (_) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
      cancelOnError: true,
    );

    _startPingLoop();
    _flushPendingPayloads();
  }

  void _startPingLoop() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_channel == null) {
        return;
      }
      _channel!.sink.add(jsonEncode(const {'type': 'ping'}));
    });
  }

  void _scheduleReconnect() {
    _pingTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _isConnecting = false;

    if (!_activeSession) {
      return;
    }

    _reconnectTimer?.cancel();
    final seconds = (_reconnectAttempt * 2) + 1;
    final delay = Duration(seconds: seconds > 30 ? 30 : seconds);
    _reconnectAttempt += 1;
    _reconnectTimer = Timer(delay, () {
      unawaited(_connect());
    });
  }

  void _handleConfigChanged() {
    if (!_activeSession) {
      return;
    }
    unawaited(deactivate().then((_) => activate()));
  }

  void _enqueuePayload(Map<String, dynamic> payload) {
    const maxPendingPayloads = 100;
    if (_pendingPayloads.length >= maxPendingPayloads) {
      _pendingPayloads.removeAt(0);
    }
    _pendingPayloads.add(Map<String, dynamic>.from(payload));
  }

  void _flushPendingPayloads() {
    final channel = _channel;
    if (channel == null || _pendingPayloads.isEmpty) {
      return;
    }

    final queuedPayloads = List<Map<String, dynamic>>.from(_pendingPayloads);
    _pendingPayloads.clear();
    for (final payload in queuedPayloads) {
      try {
        channel.sink.add(jsonEncode(payload));
      } catch (_) {
        _enqueuePayload(payload);
        _scheduleReconnect();
        return;
      }
    }
  }
}
