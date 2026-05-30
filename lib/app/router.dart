import 'package:go_router/go_router.dart';

import '../features/games/dice/dice_page.dart';
import '../features/games/number_bomb/number_bomb_page.dart';
import '../features/games/poker/poker_page.dart';
import '../features/games/truth_dare/truth_dare_page.dart';
import '../features/games/undercover/undercover_page.dart';
import '../features/games/wheel/wheel_page.dart';
import '../features/games/picker/picker_page.dart';
import '../features/home/home_page.dart';
import '../features/players/players_page.dart';
import '../features/punishment/punishment_page.dart';
import '../features/report/report_page.dart';
import '../features/room/room_host_page.dart';
import '../features/room/room_join_page.dart';
import '../features/session/session_start_page.dart';
import '../features/session/ledger_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomePage()),
    GoRoute(path: '/players', builder: (_, __) => const PlayersPage()),
    GoRoute(path: '/punishments', builder: (_, __) => const PunishmentPage()),
    GoRoute(path: '/session/start', builder: (_, __) => const SessionStartPage()),
    GoRoute(path: '/session/ledger', builder: (_, __) => const LedgerPage()),
    GoRoute(path: '/games/wheel', builder: (_, __) => const WheelPage()),
    GoRoute(path: '/games/dice', builder: (_, __) => const DicePage()),
    GoRoute(path: '/games/truth-dare', builder: (_, __) => const TruthDarePage()),
    GoRoute(path: '/games/picker', builder: (_, __) => const PickerPage()),
    GoRoute(path: '/games/undercover', builder: (_, __) => const UndercoverPage()),
    GoRoute(path: '/games/poker', builder: (_, __) => const PokerPage()),
    GoRoute(path: '/games/number-bomb', builder: (_, __) => const NumberBombPage()),
    GoRoute(path: '/room/host', builder: (_, __) => const RoomHostPage()),
    GoRoute(path: '/room/join', builder: (_, __) => const RoomJoinPage()),
    GoRoute(
      path: '/report',
      builder: (_, state) => ReportPage(
        report: state.extra as dynamic,
      ),
    ),
  ],
);
