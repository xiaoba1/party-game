import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/enums/app_enums.dart';
import '../../../data/models/app_models.dart';
import '../../../shared/widgets/punishment_dialog.dart';
import '../../../shared/widgets/session_top_bar.dart';
import '../../room/providers/room_provider.dart';
import '../../session/providers/session_provider.dart';

class UndercoverPage extends ConsumerStatefulWidget {
  const UndercoverPage({super.key});

  @override
  ConsumerState<UndercoverPage> createState() => _UndercoverPageState();
}

class _UndercoverPageState extends ConsumerState<UndercoverPage> {
  List<UndercoverWordPair> _wordPairs = [];
  UndercoverWordPair? _currentPair;
  UndercoverPhase _phase = UndercoverPhase.waiting;
  Map<String, String> _playerWords = {};
  Map<String, bool> _playerIsSpy = {};
  final _votes = <String, String>{};
  int _spyCount = AppConstants.undercoverDefaultSpies;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final json = await rootBundle.loadString('assets/data/word_pairs_undercover.json');
    final list = jsonDecode(json) as List;
    setState(() {
      _wordPairs = list
          .map((e) => UndercoverWordPair.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  Future<void> _startGame() async {
    final session = ref.read(sessionProvider);
    if (!session.isActive || session.players.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少需要 3 名玩家并开始聚会')),
      );
      return;
    }

    if (_wordPairs.isEmpty) await _loadWords();
    final pair = _wordPairs[Random().nextInt(_wordPairs.length)];
    final players = List.of(session.players)..shuffle();
    final spyIndices = <int>{};
    while (spyIndices.length < _spyCount.clamp(1, players.length - 1)) {
      spyIndices.add(Random().nextInt(players.length));
    }

    final words = <String, String>{};
    final spies = <String, bool>{};
    for (var i = 0; i < players.length; i++) {
      final isSpy = spyIndices.contains(i);
      words[players[i].id] = isSpy ? pair.spyWord : pair.civilianWord;
      spies[players[i].id] = isSpy;
    }

    setState(() {
      _currentPair = pair;
      _playerWords = words;
      _playerIsSpy = spies;
      _phase = UndercoverPhase.dealing;
      _votes.clear();
    });

    // 联机模式同步
    final room = ref.read(roomProvider);
    if (room.isHost && room.isConnected) {
      ref.read(roomProvider.notifier).broadcastGameAction({
        'type': 'undercover_start',
        'words': words,
        'spies': spies.map((k, v) => MapEntry(k, v)),
        'pairId': pair.id,
      });
    }

    HapticFeedback.mediumImpact();
  }

  void _startVoting() {
    setState(() {
      _phase = UndercoverPhase.voting;
      _votes.clear();
    });
  }

  void _castVote(String voterId, String targetId) {
    setState(() => _votes[voterId] = targetId);
    if (_votes.length >= ref.read(sessionProvider).players.length) {
      _revealResult();
    }
  }

  void _revealResult() {
    final voteCount = <String, int>{};
    for (final target in _votes.values) {
      voteCount[target] = (voteCount[target] ?? 0) + 1;
    }
    var maxVotes = 0;
    String? eliminated;
    voteCount.forEach((id, count) {
      if (count > maxVotes) {
        maxVotes = count;
        eliminated = id;
      }
    });

    setState(() => _phase = UndercoverPhase.reveal);

    if (eliminated != null && mounted) {
      final session = ref.read(sessionProvider);
      final player = session.players.firstWhere((p) => p.id == eliminated!);
      final isSpy = _playerIsSpy[player.id] ?? false;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isSpy ? '🕵️ 卧底出局！' : '😢 平民出局'),
          content: Text(
            '${player.sessionNickname} 被投票出局\n'
            '身份: ${isSpy ? "卧底" : "平民"}\n'
            '词: ${_playerWords[player.id]}',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('继续')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await PunishmentDialog.show(
                  context,
                  sessionPlayer: player,
                  punishmentText: isSpy ? '卧底被抓' : '冤死',
                  gameType: 'undercover',
                );
              },
              child: const Text('罚酒'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: const SessionTopBar(title: '谁是卧底'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_phase == UndercoverPhase.waiting) ...[
              Row(
                children: [
                  const Text('卧底人数:'),
                  ...List.generate(3, (i) {
                    final count = i + 1;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text('$count'),
                        selected: _spyCount == count,
                        onSelected: (_) => setState(() => _spyCount = count),
                      ),
                    );
                  }),
                ],
              ),
              const Spacer(),
              const Text('🕵️', textAlign: TextAlign.center, style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                '传手机查看词语，找出卧底',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _startGame,
                child: const Text('开始游戏'),
              ),
            ] else if (_phase == UndercoverPhase.dealing) ...[
              Text('传手机给下一位玩家查看词语',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: session.players.length,
                  itemBuilder: (_, i) {
                    final p = session.players[i];
                    return Card(
                      child: ListTile(
                        leading: Text(p.avatarEmoji, style: const TextStyle(fontSize: 24)),
                        title: Text(p.sessionNickname),
                        trailing: const Icon(Icons.visibility),
                        onTap: () => _showWord(context, p.id, p.sessionNickname),
                      ),
                    );
                  },
                ),
              ),
              FilledButton(
                onPressed: () => setState(() => _phase = UndercoverPhase.discussing),
                child: const Text('所有人已查看，开始讨论'),
              ),
            ] else if (_phase == UndercoverPhase.discussing) ...[
              const Spacer(),
              Text('讨论时间到？', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: _startVoting, child: const Text('开始投票')),
              const Spacer(),
            ] else if (_phase == UndercoverPhase.voting) ...[
              Text('投票出局', style: Theme.of(context).textTheme.titleMedium),
              Expanded(
                child: ListView.builder(
                  itemCount: session.players.length,
                  itemBuilder: (_, i) {
                    final voter = session.players[i];
                    return ExpansionTile(
                      title: Text('${voter.sessionNickname} 投票'),
                      subtitle: Text(_votes[voter.id] != null ? '已投票' : '未投票'),
                      children: session.players
                          .where((p) => p.id != voter.id)
                          .map((target) => ListTile(
                                title: Text(target.sessionNickname),
                                onTap: () => _castVote(voter.id, target.id),
                              ))
                          .toList(),
                    );
                  },
                ),
              ),
            ] else ...[
              const Spacer(),
              FilledButton(
                onPressed: () => setState(() => _phase = UndercoverPhase.waiting),
                child: const Text('再来一局'),
              ),
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }

  void _showWord(BuildContext context, String playerId, String nickname) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('$nickname 的词语'),
        content: Text(
          _playerWords[playerId] ?? '???',
          style: Theme.of(ctx).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('记住了，传给下一位'),
          ),
        ],
      ),
    );
  }
}
