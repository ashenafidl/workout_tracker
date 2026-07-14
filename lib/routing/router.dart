import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:workout_tracker/core/widgets/scaffold_with_navbar.dart";
import "package:workout_tracker/ui/exercises/widgets/exercises_screen.dart";
import "package:workout_tracker/ui/home/widgets/home_screen.dart";
import "package:workout_tracker/ui/more/widgets/more_screen.dart";

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _homeNavKey = GlobalKey<NavigatorState>(
  debugLabel: "home",
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

        // Branch 1: More
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
  ],
);
