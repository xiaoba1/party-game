import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/constants/app_constants.dart';
import '../report/data_export_service.dart';
import '../session/providers/session_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: '导入数据',
            onPressed: () async {
              final ok = await ref.read(dataExportServiceProvider).importFromFile();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? '导入成功' : '导入取消')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: '导出数据',
            onPressed: () => ref.read(dataExportServiceProvider).shareExport(),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => context.push('/players'),
          ),
          IconButton(
            icon: const Icon(Icons.library_books_outlined),
            onPressed: () => context.push('/punishments'),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (session.isActive) ...[
                      _ActiveSessionBanner(session: session),
                      const SizedBox(height: 20),
                    ] else ...[
                      _WelcomeCard(
                        onStart: () => context.push('/session/start'),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      '选择游戏',
                      style: Theme.of(context).textTheme.titleLarge,
                    ).animate().fadeIn(duration: 300.ms),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildListDelegate([
                  _GameCard(
                    title: '幸运转盘',
                    icon: '🎡',
                    color: AppTheme.primary,
                    onTap: () => context.push('/games/wheel'),
                  ),
                  _GameCard(
                    title: '摇骰子',
                    icon: '🎲',
                    color: AppTheme.secondary,
                    onTap: () => context.push('/games/dice'),
                  ),
                  _GameCard(
                    title: '真心话大冒险',
                    icon: '💬',
                    color: AppTheme.accent,
                    onTap: () => context.push('/games/truth-dare'),
                  ),
                  _GameCard(
                    title: '随机点名',
                    icon: '🎯',
                    color: const Color(0xFFFFB74D),
                    onTap: () => context.push('/games/picker'),
                  ),
                  _GameCard(
                    title: '谁是卧底',
                    icon: '🕵️',
                    color: const Color(0xFF7986CB),
                    onTap: () => context.push('/games/undercover'),
                  ),
                  _GameCard(
                    title: '扑克小游戏',
                    icon: '🃏',
                    color: const Color(0xFF4DB6AC),
                    onTap: () => context.push('/games/poker'),
                  ),
                  _GameCard(
                    title: '数字炸弹',
                    icon: '💣',
                    color: const Color(0xFFEF5350),
                    onTap: () => context.push('/games/number-bomb'),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      floatingActionButton: session.isActive
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/session/start'),
              icon: const Icon(Icons.celebration),
              label: const Text('开始聚会'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: -1,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.wifi_tethering), label: '创建房间'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: '加入房间'),
        ],
        onDestinationSelected: (i) {
          if (i == 0) {
            context.push('/room/host');
          } else {
            context.push('/room/join');
          }
        },
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🥳', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              '准备好聚会了吗？',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '选择玩家，开始一场欢乐聚会',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onStart,
              child: const Text('开始聚会'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

class _ActiveSessionBanner extends ConsumerWidget {
  const _ActiveSessionBanner({required this.session});
  final SessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: AppTheme.primary.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('聚会进行中',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${session.players.length} 位玩家 · ${session.drinkMode.label}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('结束聚会'),
                    content: const Text('确定结束本场聚会并生成战报？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('结束'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  final report =
                      await ref.read(sessionProvider.notifier).endSession();
                  if (report != null && context.mounted) {
                    context.push('/report', extra: report);
                  }
                }
              },
              child: const Text('结束'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
          duration: 2000.ms,
          color: color.withValues(alpha: 0.1),
        );
  }
}
