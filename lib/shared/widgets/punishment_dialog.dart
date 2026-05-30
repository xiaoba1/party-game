import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../data/models/app_models.dart';
import '../../features/session/providers/session_provider.dart';

/// 统一惩罚处理弹窗
class PunishmentDialog extends ConsumerStatefulWidget {
  const PunishmentDialog({
    super.key,
    required this.sessionPlayer,
    required this.punishmentText,
    required this.gameType,
    this.defaultCups = AppConstants.defaultPenaltyCups,
  });

  final SessionPlayerModel sessionPlayer;
  final String punishmentText;
  final String gameType;
  final int defaultCups;

  static Future<void> show(
    BuildContext context, {
    required SessionPlayerModel sessionPlayer,
    required String punishmentText,
    required String gameType,
    int defaultCups = AppConstants.defaultPenaltyCups,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PunishmentDialog(
        sessionPlayer: sessionPlayer,
        punishmentText: punishmentText,
        gameType: gameType,
        defaultCups: defaultCups,
      ),
    );
  }

  @override
  ConsumerState<PunishmentDialog> createState() => _PunishmentDialogState();
}

class _PunishmentDialogState extends ConsumerState<PunishmentDialog> {
  int _cups = AppConstants.defaultPenaltyCups;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _cups = widget.defaultCups;
  }

  Future<void> _handleAction({
    required int cups,
    bool skip = false,
  }) async {
    if (!_confirming && !skip) {
      setState(() => _confirming = true);
      return;
    }

    HapticFeedback.mediumImpact();
    await ref.read(sessionProvider.notifier).applyPenalty(
          sessionPlayerId: widget.sessionPlayer.id,
          cups: cups,
          reason: widget.punishmentText,
          gameType: widget.gameType,
          skip: skip,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final isCumulative = session.drinkMode == DrinkCountMode.cumulative;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(widget.sessionPlayer.avatarColor),
                    child: Text(widget.sessionPlayer.avatarEmoji),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.sessionPlayer.sessionNickname,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (isCumulative && widget.sessionPlayer.pendingCups > 0)
                          Text(
                            '待喝 ${widget.sessionPlayer.pendingCups} 杯',
                            style: TextStyle(
                              color: AppTheme.drinkColor,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.punishmentText,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              if (_confirming)
                Text(
                  '确认执行惩罚？',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.accent),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: '喝 $_cups 杯',
                      icon: Icons.local_bar,
                      color: AppTheme.drinkColor,
                      onTap: () => _handleAction(cups: _cups),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: '双倍',
                      icon: Icons.exposure_plus_2,
                      color: AppTheme.accent,
                      onTap: () => _handleAction(cups: _cups * 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleAction(cups: 0, skip: true),
                      icon: const Icon(Icons.skip_next),
                      label: const Text('不做惩罚'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      setState(() {
                        _cups = (_cups % 5) + 1;
                      });
                    },
                    icon: Text('$_cups', style: const TextStyle(fontWeight: FontWeight.bold)),
                    tooltip: '自定义杯数',
                  ),
                ],
              ),
              if (_confirming)
                TextButton(
                  onPressed: () => setState(() => _confirming = false),
                  child: const Text('返回修改'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

/// 选择玩家弹窗（用于指定惩罚对象）
Future<SessionPlayerModel?> showSelectPlayerDialog(
  BuildContext context,
  List<SessionPlayerModel> players, {
  String title = '选择玩家',
}) {
  return showDialog<SessionPlayerModel>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: players.length,
          itemBuilder: (_, i) {
            final p = players[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(p.avatarColor),
                child: Text(p.avatarEmoji),
              ),
              title: Text(p.sessionNickname),
              subtitle: p.pendingCups > 0 ? Text('待喝 ${p.pendingCups} 杯') : null,
              onTap: () => Navigator.pop(ctx, p),
            );
          },
        ),
      ),
    ),
  );
}
