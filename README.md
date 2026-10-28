# Workout Tracker

A lightweight Flutter app for planning workouts, tracking session progress, and keeping a history of completed training.

## Features
- Create and manage workout programs
- Track exercises and workout templates
- Run a live workout session with circuit-based logging
- Store historical session data locally on-device
- Export and import versioned JSON backups for workouts, history, and app settings

## Tech
- Flutter
- Drift + SQLite
- Go Router
- GetIt
- Material Design

## Run
```bash
flutter pub get
flutter run
```

> Android is the only configured target for this project.

## Backup and restore

Use **More → Backup & Restore** to save a JSON backup or restore one from a file.
Import validates the complete backup and asks for confirmation before replacing
the app's backed-up database records and workout preferences. Backup files
contain workout and session history, including body-weight records, and should
be treated as private data.

## Database updates
```bash
dart run build_runner build --delete-conflicting-outputs
```

Run this after changing the schema in the Drift database layer.
