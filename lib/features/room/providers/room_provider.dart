import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/app_models.dart';
import '../../session/providers/session_provider.dart';

/// 联机房间状态
class RoomState {
  const RoomState({
    this.isHost = false,
    this.isConnected = false,
    this.roomCode = '',
    this.hostIp = '',
    this.connectedClients = 0,
    this.clientChannel,
  });

  final bool isHost;
  final bool isConnected;
  final String roomCode;
  final String hostIp;
  final int connectedClients;
  final WebSocketChannel? clientChannel;

  RoomState copyWith({
    bool? isHost,
    bool? isConnected,
    String? roomCode,
    String? hostIp,
    int? connectedClients,
    WebSocketChannel? clientChannel,
  }) {
    return RoomState(
      isHost: isHost ?? this.isHost,
      isConnected: isConnected ?? this.isConnected,
      roomCode: roomCode ?? this.roomCode,
      hostIp: hostIp ?? this.hostIp,
      connectedClients: connectedClients ?? this.connectedClients,
      clientChannel: clientChannel ?? this.clientChannel,
    );
  }
}

class RoomNotifier extends StateNotifier<RoomState> {
  RoomNotifier(this.ref) : super(const RoomState());

  final Ref ref;
  HttpServer? _server;
  final _clientSockets = <WebSocket>[];
  StreamSubscription<dynamic>? _clientSubscription;

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().millisecondsSinceEpoch;
    return List.generate(4, (i) => chars[(now + i * 7) % chars.length]).join();
  }

  Future<String?> startHost() async {
    try {
      final server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        AppConstants.roomPort,
      );
      _server = server;

      final ip = await _getLocalIp();
      final code = _generateRoomCode();

      server.listen((request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final ws = await WebSocketTransformer.upgrade(request);
          _clientSockets.add(ws);
          state = state.copyWith(connectedClients: _clientSockets.length);

          ws.listen(
            (data) => _handleHostMessage(ws, data.toString()),
            onDone: () {
              _clientSockets.remove(ws);
              state = state.copyWith(connectedClients: _clientSockets.length);
            },
          );

          _sendToClient(ws, {
            'type': 'sync_state',
            'payload': _buildSessionPayload(),
          });
        } else {
          request.response.statusCode = HttpStatus.ok;
          request.response.write('Party Game Room');
          await request.response.close();
        }
      });

      state = RoomState(
        isHost: true,
        isConnected: true,
        roomCode: code,
        hostIp: ip ?? '0.0.0.0',
        connectedClients: 0,
      );

      return ip;
    } catch (e) {
      return null;
    }
  }

  Future<bool> joinRoom(String ip, String code) async {
    try {
      final channel = WebSocketChannel.connect(
        Uri.parse('ws://$ip:${AppConstants.roomPort}'),
      );

      _clientSubscription = channel.stream.listen(
        (data) => _handleClientMessage(data.toString()),
        onDone: () => state = state.copyWith(isConnected: false),
        onError: (_) => state = state.copyWith(isConnected: false),
      );

      _sendViaClient(channel, {
        'type': 'join',
        'payload': {'roomCode': code},
      });

      state = RoomState(
        isConnected: true,
        roomCode: code,
        hostIp: ip,
        clientChannel: channel,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  void broadcastGameAction(Map<String, dynamic> action) {
    if (!state.isHost) return;
    final message = jsonEncode({'type': 'game_action', 'payload': action});
    for (final ws in _clientSockets) {
      ws.add(message);
    }
  }

  void broadcastNicknameUpdate(String sessionPlayerId, String nickname) {
    broadcastGameAction({
      'type': 'player_nickname_updated',
      'sessionPlayerId': sessionPlayerId,
      'nickname': nickname,
    });
  }

  Map<String, dynamic> _buildSessionPayload() {
    final session = ref.read(sessionProvider);
    return {
      'players': session.players
          .map((p) => {
                'id': p.id,
                'playerId': p.playerId,
                'sessionNickname': p.sessionNickname,
                'pendingCups': p.pendingCups,
              })
          .toList(),
      'drinkMode': session.drinkMode.name,
    };
  }

  void _handleHostMessage(WebSocket ws, String data) {
    try {
      final msg = jsonDecode(data) as Map<String, dynamic>;
      final type = msg['type'] as String?;

      switch (type) {
        case 'join':
          _sendToClient(ws, {
            'type': 'sync_state',
            'payload': _buildSessionPayload(),
          });
        case 'player_nickname_updated':
          final payload = msg['payload'] as Map<String, dynamic>?;
          if (payload != null) {
            ref.read(sessionProvider.notifier).updateNickname(
                  sessionPlayerId: payload['sessionPlayerId'] as String,
                  newNickname: payload['nickname'] as String,
                  sessionOnly: payload['sessionOnly'] as bool? ?? false,
                );
            _broadcast(jsonEncode(msg));
          }
        case 'vote':
        case 'drink_update':
        case 'game_action':
          _broadcast(data);
        case 'ping':
          _sendToClient(ws, {'type': 'pong'});
      }
    } catch (_) {}
  }

  void _handleClientMessage(String data) {
    try {
      final msg = jsonDecode(data) as Map<String, dynamic>;
      final type = msg['type'] as String?;

      switch (type) {
        case 'sync_state':
          // Client 接收 Host 状态同步
          break;
        case 'game_action':
          final payload = msg['payload'] as Map<String, dynamic>?;
          if (payload?['type'] == 'player_nickname_updated') {
            ref.read(sessionProvider.notifier).updateNickname(
                  sessionPlayerId: payload!['sessionPlayerId'] as String,
                  newNickname: payload['nickname'] as String,
                  sessionOnly: payload['sessionOnly'] as bool? ?? false,
                );
          }
        case 'pong':
          break;
      }
    } catch (_) {}
  }

  void _broadcast(String data) {
    for (final ws in _clientSockets) {
      ws.add(data);
    }
  }

  void _sendToClient(WebSocket ws, Map<String, dynamic> message) {
    ws.add(jsonEncode(message));
  }

  void _sendViaClient(WebSocketChannel channel, Map<String, dynamic> message) {
    channel.sink.add(jsonEncode(message));
  }

  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.168.')) {
            return addr.address;
          }
        }
      }
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> disconnect() async {
    _clientSubscription?.cancel();
    state.clientChannel?.sink.close();
    for (final ws in _clientSockets) {
      await ws.close();
    }
    _clientSockets.clear();
    await _server?.close(force: true);
    _server = null;
    state = const RoomState();
  }

  String buildJoinUrl() {
    return '${AppConstants.roomScheme}://join?ip=${state.hostIp}&port=${AppConstants.roomPort}&code=${state.roomCode}';
  }
}

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>((ref) {
  return RoomNotifier(ref);
});
