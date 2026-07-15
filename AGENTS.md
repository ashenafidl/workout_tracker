# AGENTS.md

## Quick Commands

```bash
# Run the app (Android only, no iOS/web/desktop configured)
flutter run

# Code generation (required after changing database schema)
dart run build_runner build --delete-conflicting-outputs

# Lint (strict mode enabled, will fail on many rules)
flutter analyze

# Test
flutter test
```

## Architecture

- **Type:** Flutter app (not a package)
- **Database:** Drift (SQLite) with code generation - `lib/database/database.dart` + generated `database.g.dart`
- **DI:** get_it - configured in `lib/config/dependencies.dart`
- **Routing:** go_router with StatefulShellRoute for bottom nav - `lib/routing/router.dart`
- **State management:** ChangeNotifier-based ViewModels in `ui/*/view_models/`

**Directory structure:**
```
lib/
├── config/        # DI setup (get_it)
├── core/          # Theme, shared widgets
├── data/          # Repositories (business logic)
├── database/      # Drift tables + migrations
├── routing/       # go_router config
└── ui/            # Feature screens, view models, widgets
    ├── exercises/
    ├── home/
    ├── more/
    └── programs/
```

## Code Generation

After editing `lib/database/database.dart` (adding/modifying tables), run:
```bash
dart run build_runner build --delete-conflicting-outputs
```
This regenerates `lib/database/database.g.dart`. Do not edit the `.g.dart` file directly.

Database schema is at **version 2** (see `schemaVersion` in `database.dart:31`). Add migrations in `onUpgrade` when changing tables.

## Lint Rules (Non-Default)

The following are enforced beyond default flutter_lints (`analysis_options.yaml`):
- **Double quotes only** (`prefer_double_quotes`) - not single quotes
- **Strict casts/inference/raw types** enabled
- **Trailing commas required** on all parameter/argument lists
- **`prefer_const_constructors`** and **`prefer_final_locals`** enforced
- **`avoid_print`** - no print statements

## Conventions

- **Strings:** Always double quotes (`"hello"`, not `'hello'`)
- **Null safety:** Strict mode, nullable fields use `Value<T?>` in Drift companions
- **Input trimming:** All user input is trimmed before storage (see repositories)
- **ViewModels:** Registered as factories in DI (new instance per screen), repositories as singletons
- **Forms:** Use bottom sheets with `showModalBottomSheet`, handle keyboard inset via `MediaQuery.viewInsetsOf`

## Gotchas

- Only Android platform is configured in `.metadata` - no iOS, web, or desktop targets exist
- Puro is used for Flutter version management (`.puro.json` set to "stable")
- Generated `database.g.dart` is large (~970 lines) - don't manually edit it
- Database uses client-default timestamps (`DateTime.now()`) - not server-side
- No CI/CD workflows configured
