import "package:drift/drift.dart";
import "package:drift_flutter/drift_flutter.dart";
import "package:path_provider/path_provider.dart";

part "database.g.dart";

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
}

class Programs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}

class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get programId => integer().references(Programs, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get sets => integer()();
  IntColumn get position => integer()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
}

class WorkoutExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId =>
      integer().references(Workouts, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.restrict)();
  IntColumn get reps => integer()();
  IntColumn get position => integer()();
}

class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId =>
      integer().references(Workouts, #id, onDelete: KeyAction.restrict)();
  IntColumn get programId =>
      integer().references(Programs, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

// One row per circuit repetition within a session.
// circuitNumber is 1-indexed: circuit 1, circuit 2, … up to workout.sets.
class SessionCircuits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get circuitNumber => integer()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

// One row per exercise within each circuit.
// targetReps is copied from WorkoutExercises at session start so history is
// stable even if the workout template is later edited.
// actualReps is nullable — filled in as the user completes each exercise.
class SessionExerciseLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get circuitId =>
      integer().references(SessionCircuits, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.restrict)();
  IntColumn get position => integer()();
  IntColumn get targetReps => integer()();
  IntColumn get actualReps => integer().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

@DriftDatabase(
  tables: [
    Exercises,
    Programs,
    Workouts,
    WorkoutExercises,
    WorkoutSessions,
    SessionCircuits,
    SessionExerciseLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  new([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: "workout_tracker",
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
