import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../domain/entities/sensor_packet.dart';
import '../../domain/entities/distress_state.dart';

class BackendApiService {
  final String baseUrl; // e.g., 'http://10.0.2.2:8000' for Android emulator or 'http://localhost:8000'
  final String wsUrl;
  WebSocketChannel? _wsChannel;
  bool _isConnected = false;

  BackendApiService({
    this.baseUrl = 'http://localhost:8000',
    this.wsUrl = 'ws://localhost:8000/ws/live',
  });

  bool get isConnected => _isConnected;

  /// Connects to real-time WebSocket channel on the backend
  void connectWebSocket({
    required Function(Map<String, dynamic>) onMessageReceived,
    Function(dynamic)? onError,
  }) {
    try {
      final uri = Uri.parse(wsUrl);
      _wsChannel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _wsChannel?.stream.listen(
        (data) {
          try {
            final parsed = jsonDecode(data.toString());
            onMessageReceived(parsed);
          } catch (_) {}
        },
        onError: (err) {
          _isConnected = false;
          onError?.call(err);
        },
        onDone: () {
          _isConnected = false;
        },
      );
    } catch (e) {
      _isConnected = false;
    }
  }

  /// Relays sensor packet and computed distress state to backend via WebSocket
  void relayLivePacket(SensorPacket packet, DistressState state) {
    if (_wsChannel != null && _isConnected) {
      final payload = {
        'type': 'sensor_relay',
        'packet': packet.toJson(),
        'distress': {
          'score': state.score,
          'level': state.level.name,
          'summary': state.friendlySummary,
        },
      };
      _wsChannel?.sink.add(jsonEncode(payload));
    }
  }

  /// Sends escalation alert request to backend to notify trusted contacts or log crisis support
  Future<bool> sendEscalationAlert({
    required String contactId,
    required String contactPhone,
    required double distressScore,
    required String channel, // 'sms' or 'whatsapp'
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/alerts/escalate');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact_id': contactId,
          'phone_number': contactPhone,
          'distress_score': distressScore,
          'channel': channel,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  void disconnect() {
    _wsChannel?.sink.close();
    _isConnected = false;
  }
}
