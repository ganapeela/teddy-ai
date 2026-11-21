import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  String wsUrl;
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _controller = StreamController<Map<String, dynamic>>.broadcast();
  bool _isConnected = false;
  Timer? _reconnectTimer;

  WebSocketService({required this.wsUrl});

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  bool get isConnected => _isConnected;

  void updateWsUrl(String newUrl) {
    wsUrl = newUrl;
    disconnect();
    connect();
  }

  void connect() {
    _reconnectTimer?.cancel();
    try {
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            _controller.add(json);
          } catch (e) {
            print('WS json decode error: $e');
          }
        },
        onError: (error) {
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          _isConnected = false;
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void send(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void subscribe(String instrument) {
    send({
      'action': 'SUBSCRIBE',
      'instrument': instrument,
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _isConnected = false;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
