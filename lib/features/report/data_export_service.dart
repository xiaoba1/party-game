import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/repository_providers.dart';
import '../../data/models/app_models.dart';

/// 数据导入导出服务
class DataExportService {
  DataExportService(this.ref);
  final Ref ref;

  Future<Map<String, dynamic>> exportAll() async {
    final players = await ref.read(playerRepositoryProvider).getAll();
    final punishments = await ref.read(punishmentRepositoryProvider).getAll();
    final customPunishments =
        punishments.where((p) => p.source == 'custom').toList();
    final wheels = await ref.read(wheelRepositoryProvider).getAll();
    final customWheels = wheels.where((w) => !w.isBuiltIn).toList();

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'players': players.map((p) => p.toMap()).toList(),
      'punishments': customPunishments.map((p) => p.toMap()).toList(),
      'wheelTemplates': customWheels.map((w) => w.toMap()).toList(),
    };
  }

  Future<void> shareExport() async {
    final data = await exportAll();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/party_game_export_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: '聚会游戏集数据备份');
  }

  Future<bool> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return false;

    final content = await result.files.single.xFile.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    if (data['players'] != null) {
      final players = (data['players'] as List)
          .map((e) => PlayerModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      await ref.read(playerRepositoryProvider).importAll(players);
    }

    if (data['punishments'] != null) {
      final items = (data['punishments'] as List)
          .map((e) => PunishmentModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      await ref.read(punishmentRepositoryProvider).importAll(items);
    }

    return true;
  }
}

final dataExportServiceProvider = Provider((ref) => DataExportService(ref));
