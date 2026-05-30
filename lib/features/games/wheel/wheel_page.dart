import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/enums/app_enums.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/app_models.dart';
import '../../../shared/widgets/punishment_dialog.dart';
import '../../../shared/widgets/session_top_bar.dart';
import '../../players/providers/players_provider.dart';
import '../../session/providers/session_provider.dart';
import 'widgets/wheel_painter.dart';

class WheelPage extends ConsumerStatefulWidget {
  const WheelPage({super.key});

  @override
  ConsumerState<WheelPage> createState() => _WheelPageState();
}

class _WheelPageState extends ConsumerState<WheelPage>
    with SingleTickerProviderStateMixin {
  WheelTemplateModel? _template;
  List<WheelOptionModel> _options = [];
  bool _spinning = false;
  double _rotation = 0;
  int? _resultIndex;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _spinning = false);
        _onSpinComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadTemplate(WheelTemplateModel template) async {
    setState(() {
      _template = template;
      _options = List.from(template.options);
      _resultIndex = null;
    });
  }

  void _spin() {
    if (_spinning || _options.isEmpty) return;
    HapticFeedback.mediumImpact();

    final random = Random();
    _resultIndex = random.nextInt(_options.length);
    final sliceAngle = 2 * pi / _options.length;
    final targetRotation = _rotation +
        (4 + random.nextInt(4)) * 2 * pi +
        (_options.length - _resultIndex! - 0.5) * sliceAngle;

    _animation = Tween<double>(begin: _rotation, end: targetRotation).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    )..addListener(() {
        setState(() => _rotation = _animation.value);
      });

    setState(() => _spinning = true);
    _controller.forward(from: 0);
  }

  Future<void> _onSpinComplete() async {
    if (_resultIndex == null) return;
    HapticFeedback.heavyImpact();

    final option = _options[_resultIndex!];
    final session = ref.read(sessionProvider);

    String resultText = option.label;
    PunishmentModel? punishment;

    if (option.type == WheelOptionType.punishment.name && option.punishmentId != null) {
      punishment = await ref.read(punishmentRepositoryProvider).getById(option.punishmentId!);
      if (punishment != null) resultText = punishment.content;
    } else if (option.type == WheelOptionType.randomTag.name && option.randomTag != null) {
      punishment = await ref.read(punishmentsProvider.notifier).drawRandom(
            tag: option.randomTag,
          );
      if (punishment != null) resultText = punishment.content;
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🎡 转盘结果'),
        content: Text(resultText, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
          if (session.isActive)
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final player = await showSelectPlayerDialog(
                  context,
                  session.players,
                  title: '谁来执行？',
                );
                if (player != null && mounted) {
                  await PunishmentDialog.show(
                    context,
                    sessionPlayer: player,
                    punishmentText: resultText,
                    gameType: 'wheel',
                  );
                }
              },
              child: const Text('执行惩罚'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(wheelTemplatesProvider);

    return Scaffold(
      appBar: const SessionTopBar(title: '幸运转盘'),
      body: Column(
        children: [
          templatesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (templates) {
              if (_template == null && templates.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadTemplate(templates.first);
                });
              }
              return SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: templates.length,
                  itemBuilder: (_, i) {
                    final t = templates[i];
                    final selected = _template?.id == t.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(t.name),
                        selected: selected,
                        onSelected: (_) => _loadTemplate(t),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          Expanded(
            child: _options.isEmpty
                ? const Center(child: Text('请选择或创建转盘模板'))
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: _rotation,
                        child: CustomPaint(
                          size: const Size(300, 300),
                          painter: WheelPainter(options: _options),
                        ),
                      ).animate(target: _spinning ? 1 : 0).shimmer(
                            duration: 500.ms,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                      const Icon(Icons.arrow_drop_down, size: 40, color: Colors.white),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _spinning ? null : () => _showEditOptions(context),
                  icon: const Icon(Icons.edit),
                  label: Text('编辑 (${_options.length})'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _spinning || _options.isEmpty ? null : _spin,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_spinning ? '旋转中...' : '开始旋转'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, scrollController) => _WheelEditor(
          options: _options,
          scrollController: scrollController,
          onSave: (options) async {
            setState(() => _options = options);
            if (_template != null && !_template!.isBuiltIn) {
              await ref.read(wheelRepositoryProvider).save(
                    WheelTemplateModel(
                      id: _template!.id,
                      name: _template!.name,
                      options: options,
                    ),
                  );
            }
          },
          onSaveAsTemplate: (name, options) async {
            final id = AppDatabase.instance.generateId();
            await ref.read(wheelRepositoryProvider).save(
                  WheelTemplateModel(id: id, name: name, options: options),
                );
            ref.invalidate(wheelTemplatesProvider);
          },
        ),
      ),
    );
  }
}

class _WheelEditor extends StatefulWidget {
  const _WheelEditor({
    required this.options,
    required this.scrollController,
    required this.onSave,
    required this.onSaveAsTemplate,
  });

  final List<WheelOptionModel> options;
  final ScrollController scrollController;
  final ValueChanged<List<WheelOptionModel>> onSave;
  final void Function(String name, List<WheelOptionModel> options) onSaveAsTemplate;

  @override
  State<_WheelEditor> createState() => _WheelEditorState();
}

class _WheelEditorState extends State<_WheelEditor> {
  late List<WheelOptionModel> _options;
  final _newOptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _options = List.from(widget.options);
  }

  @override
  void dispose() {
    _newOptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('编辑选项 (${_options.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: () {
                  widget.onSave(_options);
                  Navigator.pop(context);
                },
                child: const Text('应用'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newOptionController,
                  decoration: const InputDecoration(hintText: '添加新选项'),
                  onSubmitted: (_) => _addOption(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: _addOption,
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            scrollController: widget.scrollController,
            itemCount: _options.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _options.removeAt(oldIndex);
                _options.insert(newIndex, item);
              });
            },
            itemBuilder: (_, i) {
              final opt = _options[i];
              return ListTile(
                key: ValueKey('$i-${opt.label}'),
                leading: Text('${i + 1}', style: const TextStyle(color: Colors.grey)),
                title: Text(opt.label),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _options.removeAt(i)),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton(
            onPressed: () async {
              final nameController = TextEditingController();
              final name = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('保存为模板'),
                  content: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: '模板名称'),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, nameController.text),
                      child: const Text('保存'),
                    ),
                  ],
                ),
              );
              if (name != null && name.trim().isNotEmpty) {
                widget.onSaveAsTemplate(name.trim(), _options);
              }
              nameController.dispose();
            },
            child: const Text('保存为新模板'),
          ),
        ),
      ],
    );
  }

  void _addOption() {
    final text = _newOptionController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _options.add(WheelOptionModel(label: text, type: 'text'));
      _newOptionController.clear();
    });
  }
}
