import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../data/models/app_models.dart';
import 'data_export_service.dart';

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key, this.report});

  final PartyReportModel? report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('聚会战报')),
        body: const Center(child: Text('暂无战报数据')),
      );
    }

    final dateFormat = DateFormat('MM月dd日 HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('聚会战报'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '导出数据',
            onPressed: () async {
              await ref.read(dataExportServiceProvider).shareExport();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppTheme.primary.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    '聚会结束',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${dateFormat.format(report!.startedAt)} - ${dateFormat.format(report!.endedAt)}',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('喝酒排行榜 🍺', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (report!.playerStats.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('本场无人罚酒，下次加油！')),
              ),
            )
          else
            ...report!.playerStats.asMap().entries.map((entry) {
              final i = entry.key;
              final stat = entry.value;
              final medals = ['🥇', '🥈', '🥉'];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(
                    i < 3 ? medals[i] : '${i + 1}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(stat.nickname),
                  trailing: Text(
                    '${stat.totalDrinks} 杯',
                    style: const TextStyle(
                      color: AppTheme.drinkColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          if (report!.gameLogs.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('精彩瞬间', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...report!.gameLogs.take(20).map(
                  (log) => Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.history, size: 18),
                      title: Text(log, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await ref.read(dataExportServiceProvider).importFromFile();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? '导入成功' : '导入取消或失败')),
                );
              }
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('从文件导入数据'),
          ),
        ],
      ),
    );
  }
}
