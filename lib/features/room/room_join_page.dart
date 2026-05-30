import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_constants.dart';
import 'providers/room_provider.dart';

class RoomJoinPage extends ConsumerStatefulWidget {
  const RoomJoinPage({super.key});

  @override
  ConsumerState<RoomJoinPage> createState() => _RoomJoinPageState();
}

class _RoomJoinPageState extends ConsumerState<RoomJoinPage> {
  final _ipController = TextEditingController();
  final _codeController = TextEditingController();
  bool _joining = false;
  bool _useScanner = true;

  Future<void> _join({String? ip, String? code}) async {
    final hostIp = ip ?? _ipController.text.trim();
    final roomCode = code ?? _codeController.text.trim().toUpperCase();

    if (hostIp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入 Host IP 地址')),
      );
      return;
    }

    setState(() => _joining = true);
    final ok = await ref.read(roomProvider.notifier).joinRoom(hostIp, roomCode);
    setState(() => _joining = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已加入房间')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('加入失败，请确认在同一 WiFi/热点下')),
      );
    }
  }

  void _onQrDetected(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || !raw.startsWith(AppConstants.roomScheme)) continue;

      final uri = Uri.parse(raw.replaceFirst('://', '://'));
      final ip = uri.queryParameters['ip'];
      final code = uri.queryParameters['code'];
      if (ip != null) {
        _join(ip: ip, code: code ?? '');
        return;
      }
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('加入房间'),
        actions: [
          IconButton(
            icon: Icon(_useScanner ? Icons.keyboard : Icons.qr_code_scanner),
            onPressed: () => setState(() => _useScanner = !_useScanner),
          ),
        ],
      ),
      body: _useScanner
          ? Column(
              children: [
                Expanded(
                  child: MobileScanner(onDetect: _onQrDetected),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('扫描 Host 展示的二维码'),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'Host IP 地址',
                      hintText: '192.168.x.x',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: '房间码（可选）',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _joining ? null : () => _join(),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: Text(_joining ? '加入中...' : '加入房间'),
                  ),
                ],
              ),
            ),
    );
  }
}
