# Workout Tracker

A lightweight Flutter app for planning workouts, tracking session progress, and keeping a history of completed training.

## Features
- Create and manage workout programs
- Track exercises and workout templates
- Run a live workout session with circuit-based logging
- Store historical session data locally on-device

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

## Database updates
```bash
dart run build_runner build --delete-conflicting-outputs
```

Run this after changing the schema in the Drift database layer.
