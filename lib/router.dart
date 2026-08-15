import 'package:go_router/go_router.dart';

import 'features/ble/connect_screen.dart';
import 'features/leaderboard/funnel_search_screen.dart';
import 'features/leaderboard/leaderboard_screen.dart';

final router = GoRouter(
  initialLocation: '/connect',
  routes: [
    GoRoute(
      path: '/connect',
      builder: (context, state) => const ConnectScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/funnels',
      builder: (context, state) => const FunnelSearchScreen(),
    ),
  ],
);
