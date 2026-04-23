import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/games/pour_match/pour_match_screen.dart';
import '../features/games/memory_flow/memory_flow_screen.dart';
import '../features/games/reaction_rush/reaction_rush_screen.dart';
import '../features/games/volume_logic/volume_logic_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (ctx, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/game/pour-match',
      builder: (ctx, state) {
        final level = int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;
        return PourMatchScreen(level: level);
      },
    ),
    GoRoute(
      path: '/game/memory-flow',
      builder: (ctx, state) => const MemoryFlowScreen(),
    ),
    GoRoute(
      path: '/game/reaction-rush',
      builder: (ctx, state) => const ReactionRushScreen(),
    ),
    GoRoute(
      path: '/game/volume-logic',
      builder: (ctx, state) {
        final level = int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;
        return VolumeLogicScreen(level: level);
      },
    ),
  ],
);
