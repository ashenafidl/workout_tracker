import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:workout_tracker/core/widgets/scaffold_with_navbar.dart";
import "package:workout_tracker/data/models/challenge.dart";
import "package:workout_tracker/data/models/workout.dart";
import "package:workout_tracker/ui/exercises/widgets/exercises_screen.dart";
import "package:workout_tracker/ui/history/widgets/history_screen.dart";
import "package:workout_tracker/ui/home/widgets/home_screen.dart";
import "package:workout_tracker/ui/more/widgets/more_screen.dart";
import "package:workout_tracker/ui/programs/widgets/challenge_screen.dart";
import "package:workout_tracker/ui/programs/widgets/program_detail_screen.dart";
import "package:workout_tracker/ui/programs/widgets/programs_screen.dart";
import "package:workout_tracker/ui/programs/widgets/workout_screen.dart";
import "package:workout_tracker/ui/session/widgets/workout_session_screen.dart";
import "package:workout_tracker/ui/stats/widgets/stats_screen.dart";

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _homeNavKey = GlobalKey<NavigatorState>(
  debugLabel: "home",
);
final GlobalKey<NavigatorState> _programsNavKey = GlobalKey<NavigatorState>(
  debugLabel: "programs",
);
final GlobalKey<NavigatorState> _statsNavKey = GlobalKey<NavigatorState>(
  debugLabel: "stats",
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
                  path: ":programId(\\d+)",
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final raw = state.pathParameters["programId"]!;
                    final programId = int.tryParse(raw);

                    if (programId == null) {
                      return const Scaffold(
                        body: Center(child: Text("Invalid program")),
                      );
                    }

                    return ProgramDetailScreen(programId: programId);
                  },
                ),
                GoRoute(
                  path: "workout",
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final args = state.extra as WorkoutScreenArgs;
                    return WorkoutScreen(
                      programId: args.programId,
                      workoutId: args.workoutId,
                      initialName: args.initialName,
                      initialSets: args.initialSets,
                      initialKind: args.initialKind,
                      initialRestDurationSeconds:
                          args.initialRestDurationSeconds,
                      initialExercises: args.initialExercises,
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // Branch 2: Stats
        StatefulShellBranch(
          navigatorKey: _statsNavKey,
          routes: [
            GoRoute(
              path: "/stats",
              builder: (context, state) => const StatsScreen(),
            ),
          ],
        ),

        // Branch 3: History
        StatefulShellBranch(
          navigatorKey: _historyNavKey,
          routes: [
            GoRoute(
              path: "/history",
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),

        // Branch 4: More
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
      routes: [
        GoRoute(
          path: "challenge",
          builder: (context, state) {
            final args = state.extra as ChallengeScreenArgs;

            return ChallengeScreen(
              workoutWithExercises: args.workoutWithExercises,
              programId: args.programId,
            );
          },
        ),
      ],
    ),
  ],
);
