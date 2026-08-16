import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:workout_tracker/core/widgets/scaffold_with_navbar.dart";
import "package:workout_tracker/data/models/workout_session_args.dart";
import "package:workout_tracker/ui/exercises/widgets/exercises_screen.dart";
import "package:workout_tracker/ui/history/widgets/history_screen.dart";
import "package:workout_tracker/ui/home/widgets/home_screen.dart";
import "package:workout_tracker/ui/more/widgets/more_screen.dart";
import "package:workout_tracker/ui/programs/widgets/program_detail_screen.dart";
import "package:workout_tracker/ui/programs/widgets/programs_screen.dart";
import "package:workout_tracker/ui/session/widgets/workout_session_screen.dart";

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _homeNavKey = GlobalKey<NavigatorState>(
  debugLabel: "home",
);
final GlobalKey<NavigatorState> _programsNavKey = GlobalKey<NavigatorState>(
  debugLabel: "programs",
);
final GlobalKey<NavigatorState> _historyNavKey = GlobalKey<NavigatorState>(
  debugLabel: "history",
);
final GlobalKey<NavigatorState> _moreNavKey = GlobalKey<NavigatorState>(
  debugLabel: "more",
);

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: "/",
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ScaffoldWithNavbar(navigationShell: navigationShell),
      branches: [
        // Branch 0: Home
        StatefulShellBranch(
          navigatorKey: _homeNavKey,
          routes: [
            GoRoute(path: "/", builder: (context, state) => const HomeScreen()),
          ],
        ),

        // Branch 1: Programs
        StatefulShellBranch(
          navigatorKey: _programsNavKey,
          routes: [
            GoRoute(
              path: "/programs",
              builder: (context, state) => const ProgramsScreen(),
              routes: [
                GoRoute(
                  path: ":programId",
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final programId = int.parse(
                      state.pathParameters["programId"]!,
                    );
                    return ProgramDetailScreen(programId: programId);
                  },
                ),
              ],
            ),
          ],
        ),

        // Branch 2: History
        StatefulShellBranch(
          navigatorKey: _historyNavKey,
          routes: [
            GoRoute(
              path: "/history",
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),

        // Branch 3: More
        StatefulShellBranch(
          navigatorKey: _moreNavKey,
          routes: [
            GoRoute(
              path: "/more",
              builder: (context, state) => const MoreScreen(),
              routes: [
                GoRoute(
                  path: "exercises",
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const ExercisesScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: "/session",
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final args = state.extra as WorkoutSessionArgs;
        return WorkoutSessionScreen(args: args);
      },
    ),
  ],
);
