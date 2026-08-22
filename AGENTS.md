# AGENTS.md

## Commands

```bash
# Run the app (Android only - no iOS/web/desktop targets exist)
flutter run

# Codegen (required after editing lib/database/database.dart)
dart run build_runner build --delete-conflicting-outputs

# Lint/typecheck (strict rules - treat as the verification gate)
flutter analyze

# Test - NOTE: no test/ directory exists yet; this fails with "No test files found"
flutter test
```

## Architecture

Flutter app. Entry: `lib/main.dart` -> `setupDependencies()` (`lib/config/dependencies.dart`) -> `MaterialApp.router` with `appRouter`.

- **Database:** Drift (SQLite) - tables + schema in `lib/database/database.dart`, generated code in `database.g.dart` (never edit). Drift builder is wired via `build.yaml`.
- **DI:** get_it - repositories/services as singletons, most ViewModels as factories. `WorkoutSessionViewModel` uses `registerFactoryParam<..., WorkoutSessionArgs, AppDatabase?>` because it needs per-navigation args.
- **Routing:** go_router `StatefulShellRoute.indexedStack` with 4 bottom-nav branches (Home `/`, Programs `/programs`, History `/history`, More `/more`). Detail screens (program detail, exercises) pop out of the shell via `parentNavigatorKey: _rootNavigatorKey`. The workout session lives at root `/session` and receives `WorkoutSessionArgs` via `state.extra`.
- **State:** ChangeNotifier ViewModels in `lib/ui/<feature>/view_models/`, screens/widgets in `widgets/`.

## Database / Migrations

- `schemaVersion` is **1** (`database.dart`). `MigrationStrategy` currently only has `onCreate`; if you add/alter tables you must bump the version AND write an `onUpgrade` step, then run build_runner.
- FKs mix cascade deletes (Workouts->WorkoutExercises, Sessions->Circuits->Logs) and restrict deletes (Programs/Sessions/Exercises) - deleting a referenced Exercise or Program fails by design.
- Timestamps use client defaults (`DateTime.now()`), not DB-side.

## Style (strict analyzer - `flutter analyze` fails on these)

- Double quotes only; trailing commas required everywhere; `const` where possible.
- `strict-casts/inference/raw-types` on; `avoid_print`; `no_default_cases`; exhaustive switch handling enforced.
- User-facing text input is trimmed before storage (see repos in `lib/data/repositories/`).

## Gotchas

- Only Android platform configured (`.metadata`); don't try `flutter run -d ios/chrome/windows`.
- Puro manages the Flutter SDK here (`.puro.json`: env "stable"); plain `flutter` assumes the right env is active.
- Generated `database.g.dart` is ~6000 lines - regenerate, never hand-edit.
- No CI configured; no tests exist yet.
