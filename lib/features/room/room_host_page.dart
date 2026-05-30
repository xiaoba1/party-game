import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../features/session/providers/session_provider.dart';
import 'providers/room_provider.dart';

class RoomHostPage extends ConsumerStatefulWidget {
  const RoomHostPage({super.key});

  @override
  ConsumerState<RoomHostPage> createState() => _RoomHostPageState();
}

class _RoomHostPageState extends ConsumerState<RoomHostPage> {
  String? _ip;
  bool _starting = false;

  Future<void> _startRoom() async {
    final session = ref.read(sessionProvider);
    if (!session.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先开始聚会再创建房间')),
      );
      return;
    }

    setState(() => _starting = true);
    final ip = await ref.read(roomProvider.notifier).startHost();
    setState(() {
      _starting = false;
      _ip = ip;
    });

    if (ip == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('创建房间失败，请检查网络权限')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('创建房间')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (!room.isConnected) ...[
              const Spacer(),
              const Icon(Icons.wifi_tethering, size: 64),
              const SizedBox(height: 16),
              const Text(
                '作为 Host 创建局域网房间\n其他玩家扫码或输入 IP 加入',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _starting ? null : _startRoom,
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                child: Text(_starting ? '创建中...' : '创建房间'),
              ),
            ] else ...[
              Text('房间码: ${room.roomCode}',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('IP: ${room.hostIp}:${AppConstants.roomPort}'),
              const SizedBox(height: 24),
              QrImageView(
                data: ref.read(roomProvider.notifier).buildJoinUrl(),
                size: 200,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 16),
              Text('已连接 ${room.connectedClients} 台设备'),
              const Spacer(),
              OutlinedButton(
                onPressed: () => ref.read(roomProvider.notifier).disconnect(),
                child: const Text('关闭房间'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
