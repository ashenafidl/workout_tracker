# AGENTS.md

## Commands

```bash
flutter pub get
flutter run                     # Android only; no iOS/web/desktop targets

# After ANY edit to lib/database/database.dart:
dart run build_runner build --delete-conflicting-outputs
# emits lib/database/database.g.dart (and database.steps.dart once a v2+ snapshot exists)

# For a new schema version (snapshots are NOT produced by build_runner):
dart run drift_dev schema dump \
  lib/database/database.dart \
  drift_schemas/workout_tracker/drift_schema_vN.json
dart run drift_dev schema generate \
  drift_schemas/workout_tracker test/drift/workout_tracker/generated

flutter analyze                 # verification gate: keep at 0 issues
flutter test
flutter test test/backup/backup_service_test.dart --plain-name "..."
```

Verification order: build_runner -> `flutter analyze` -> `flutter test`.

`flutter analyze` is clean and `flutter test` is green. `test/drift/workout_tracker/schema_test.dart` checks a fresh install lands at v2 and matches the snapshot; `migration_test.dart` covers v1 -> v2.

## Code style (repo-specific)

- Constructors are declared `new(...)` / `const new(...)` in every class in `lib/` (deliberate, commit `0c60fed`). Dart treats a constructor named `new` as the unnamed one, so call sites stay `AppTheme()` / `AppDatabase.new`. Do not "fix" these.
- Import Flutter widgets from `package:material_ui/material_ui.dart`, not `package:flutter/material.dart` - it re-exports the widget API and is used throughout.
- Dot shorthands everywhere (`.system`, `.circular(8)`, `Icons.repeat`, tear-offs like `AppDatabase.new`); double-quoted strings.
- `require_trailing_commas` puts closing parens on their own line with flat args. Formatting artifact, not a bug.
- Drift style: inline `(query..where(...)).method()` cascades, named `OrderingTerm(expression:)`, `watch()` for anything reactive.

`analysis_options.yaml` is stricter than `flutter_lints`: `strict-casts`/`strict-inference`/`strict-raw-types`, `type_annotate_public_apis`, `always_declare_return_types`, `prefer_final_locals`/`prefer_final_fields`, `require_trailing_commas`, `prefer_double_quotes`, `directives_ordering` (`dart:` then `package:`, alphabetical), `avoid_dynamic_calls`, `avoid_print`, `exhaustive_cases`/`no_default_cases`, `depend_on_referenced_packages`. Excluded from analysis: `build/`, platform dirs, and `test/drift`.

## Architecture

`lib/main.dart` -> `setupDependencies()` (`lib/config/dependencies.dart`) -> `MaterialApp.router` with `appRouter` (`lib/routing/router.dart`).

- **DI (get_it):** services/repos are lazy singletons, most ViewModels are factories. Deliberate lazy-singleton VMs: `HomeViewModel`, `HistoryViewModel`, `ProgramDetailViewModel`, `ScheduleViewModel`, `BodyWeightViewModel` (their streams survive tab switches). `WorkoutSessionViewModel` uses `registerFactoryParam<..., WorkoutSessionArgs, AppDatabase?>` so tests can inject a DB; `ChallengeViewModel` takes `(WorkoutWithExercises, int programId)`.
- **Routing:** `StatefulShellRoute.indexedStack` with 5 branches (`/`, `/programs`, `/stats`, `/history`, `/more`). Detail routes set `parentNavigatorKey: _rootNavigatorKey` to cover the bottom nav. `/session` is root-level, reads `WorkoutSessionArgs` from `state.extra` with an unchecked cast; `/session/challenge` nests under it.
- **UI/state:** `ChangeNotifier` ViewModels in `lib/ui/<feature>/view_models/`; screens are always `widgets/<name>_screen.dart`. Repos return Drift `watch()`/`watchSingle()` streams consumed by `StreamBuilder` - extend a repo stream rather than adding manual refresh.
- **Input hygiene:** the repo layer trims all user text and stores empty optional strings as `null` (`exercise_repo.dart`, `workout_repo.dart`, `program_repo.dart`).
- **Features:** program/workout/exercise planning, circuit-based session logging, challenges, stats + body-weight logs, schedule + streak calendar, JSON backup/restore under More.

## Database / schema

- `schemaVersion` is **2** (v2 added `ChallengeScreenVisits`). `onUpgrade` uses `stepByStep` from `database.steps.dart` (regenerate with `dart run drift_dev make-migrations`). Never hand-edit `database.g.dart`, `database.steps.dart`, or `test/drift/**/generated/*`.
- Tracked snapshots: `drift_schemas/workout_tracker/drift_schema_v*.json` (v1, v2). For a new version: bump it, dump a new snapshot (snapshots are immutable - never regenerate old ones), run `make-migrations`, add the `fromNToN+1` step and extend the migration test together.
- `StreakStats` is a singleton table (one row, `id == 1`) seeded in `onCreate`; `getSingle()` throws without it. Any upgrade that recreates it must reseed. Streak logic uses the schedule (`StreakService` depends on `ScheduleRepo` / `WorkoutScheduleChanges.weekdayMask`), not only session history.
- FK delete behaviour is mixed and deliberate: cascade on `ExerciseSupportedTypes.exerciseId`, `WorkoutExercises.workoutId`, `SessionCircuits.sessionId`, `SessionExerciseLogs.circuitId`, `ChallengeLogs.sessionId`; restrict on `WorkoutExercises.exerciseId`, `WorkoutSessions.workoutId`/`programId`, `SessionExerciseLogs.exerciseId`, `ChallengeLogs.exerciseId`. `Workouts.programId` has no `onDelete` (NO ACTION), so `deleteProgram` throws while workouts remain.
- Exactly one active program; `ProgramRepo.setActiveProgram` clears the others in a transaction.
- `WorkoutExercises` is the template; `SessionExerciseLogs` snapshots `target*`, `exerciseType`, and `side` at session start so history survives template edits.
- `ExerciseSide` is `left`/`right`/`both`, persisted with `intEnum`; `side` columns are nullable and `null` means no side. Never reorder intEnum values - ordinals are stored in the DB. `isBilateral` is an `Exercises` trait, independent of the per-workout `side`.
- All workout/rest durations come from `SessionDurations` (`lib/data/services/session_durations.dart`); history, stats, the streak calendar and the session summary read from it. Circuit sessions: rest = gaps between circuits, workout = elapsed - rest. Challenges: timed entries count for their length; with rep entries, the first-to-last span also counts but only inside `ChallengeScreenVisits` (foreground stretches, created on first log, `closedAt` = last log). No visits (pre-v2 data) falls back to the full span.
- Timestamps use client-side `DateTime.now()` defaults, never DB-side; set `updatedAt` manually on updates.

## Backup / restore

- JSON uses `format: workout_tracker_backup`, `backupVersion: 1`, and `databaseSchemaVersion` in `_supportedSchemaVersions` (1, 2). Schema 1 backups omit `challengeScreenVisits` and restore it empty; schema 2 requires it. A schema bump needs `_parseBackup` updated the same way.
- Only these SharedPreferences keys are backed up/restored: `rest_duration_seconds`, `workout_index_<programId>`, `program_run_start_<programId>` (see `SharedPreferenceService`). Restore is transactional across DB + prefs and removes obsolete scoped keys.
- Backups include private workout/body-weight history.

## Gotchas

- `flutter`/`dart` resolve to `~/.flutter/flutter` (Flutter 3.50 / Dart 3.14). `.vscode/settings.json` points at a stale Puro path and there is no `.puro.json` - use the commands on PATH.
- No audio assets: `SoundService` synthesizes PCM WAV bytes in Dart and plays them via `BytesSource`.
- `android/app/build.gradle.kts`: debug adds `applicationIdSuffix = ".debug"` and release is signed with debug keys, so both install side by side.
- No CI config, `opencode.json`, other agent instruction files, or task runner in this repo.
