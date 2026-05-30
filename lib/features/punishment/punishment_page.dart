import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums/app_enums.dart';
import '../../data/models/app_models.dart';
import '../players/providers/players_provider.dart';

class PunishmentPage extends ConsumerStatefulWidget {
  const PunishmentPage({super.key});

  @override
  ConsumerState<PunishmentPage> createState() => _PunishmentPageState();
}

class _PunishmentPageState extends ConsumerState<PunishmentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _filterTag;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final tags = [null, ...PunishmentTag.values.map((e) => e.name)];
        setState(() => _filterTag = tags[_tabController.index]);
        ref.read(punishmentsProvider.notifier).loadPunishments(tag: _filterTag);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final punishmentsAsync = ref.watch(punishmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('惩罚奖励库'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: '全部'),
            ...PunishmentTag.values.map((t) => Tab(text: t.label)),
          ],
        ),
      ),
      body: punishmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('暂无条目'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, i) => _PunishmentTile(item: items[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final contentController = TextEditingController();
    var selectedTag = PunishmentTag.dare.name;
    var selectedDifficulty = PunishmentDifficulty.mild.name;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('添加自定义条目'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: '内容'),
                maxLines: 3,
              ),
              DropdownButtonFormField<String>(
                value: selectedTag,
                decoration: const InputDecoration(labelText: '类型'),
                items: PunishmentTag.values
                    .map((t) => DropdownMenuItem(value: t.name, child: Text(t.label)))
                    .toList(),
                onChanged: (v) => setState(() => selectedTag = v!),
              ),
              DropdownButtonFormField<String>(
                value: selectedDifficulty,
                decoration: const InputDecoration(labelText: '难度'),
                items: PunishmentDifficulty.values
                    .map((d) => DropdownMenuItem(value: d.name, child: Text(d.label)))
                    .toList(),
                onChanged: (v) => setState(() => selectedDifficulty = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                if (contentController.text.trim().isEmpty) return;
                await ref.read(punishmentsProvider.notifier).addCustom(
                      content: contentController.text.trim(),
                      tag: selectedTag,
                      difficulty: selectedDifficulty,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
    contentController.dispose();
  }
}

class _PunishmentTile extends ConsumerWidget {
  const _PunishmentTile({required this.item});
  final PunishmentModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tag = PunishmentTag.values
        .cast<PunishmentTag?>()
        .firstWhere((t) => t?.name == item.tag, orElse: () => null);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.content),
        subtitle: Text(
          '${tag?.label ?? item.tag} · ${PunishmentDifficulty.fromString(item.difficulty).label}'
          '${item.source == 'built_in' ? ' · 内置' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                item.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: item.isFavorite ? Colors.red : null,
              ),
              onPressed: () =>
                  ref.read(punishmentsProvider.notifier).toggleFavorite(item),
            ),
            if (item.source == 'custom')
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    ref.read(punishmentsProvider.notifier).deleteCustom(item.id),
              ),
          ],
        ),
      ),
    );
  }
}
