import "package:drift/drift.dart";
import "package:drift_flutter/drift_flutter.dart";
import "package:path_provider/path_provider.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/models/programs.dart";

import "database.steps.dart";

part "database.g.dart";

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  IntColumn get type =>
      intEnum<ExerciseType>().withDefault(const Constant(0))();
  BoolColumn get isBilateral => boolean().withDefault(const Constant(false))();
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
  IntColumn get kind => intEnum<WorkoutKind>().withDefault(const Constant(0))();
  IntColumn get sets => integer()();
  IntColumn get position => integer()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
}

// Template: what the user plans to do each circuit.
// Only the columns relevant to the exercise type are non-null.
class WorkoutExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId =>
      integer().references(Workouts, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.restrict)();
  IntColumn get position => integer()();

  // Only set when this exercise is bilateral.
  IntColumn get side => intEnum<ExerciseSide>().nullable()();

  // reps — ExerciseType.reps
  IntColumn get targetReps => integer().nullable()();

  // duration — ExerciseType.duration
  IntColumn get targetDurationSeconds => integer().nullable()();
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

// Log: what the user actually did.
// target* columns are copied from WorkoutExercises at session start so
// history is stable if the template is later edited.
// actual* columns are filled in as the user completes each exercise.
class SessionExerciseLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get circuitId =>
      integer().references(SessionCircuits, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.restrict)();
  IntColumn get position => integer()();

  // Snapshot of ExerciseType at session start — keeps log self-contained.
  IntColumn get exerciseType =>
      intEnum<ExerciseType>().withDefault(const Constant(0))();

  // Snapshot of the per-workout side at session start, so history still shows
  // the side even if the workout template is edited later.
  IntColumn get side => intEnum<ExerciseSide>().nullable()();
  // reps
  IntColumn get targetReps => integer().nullable()();
  IntColumn get actualReps => integer().nullable()();

  // duration
  IntColumn get targetDurationSeconds => integer().nullable()();
  IntColumn get actualDurationSeconds => integer().nullable()();

  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class ChallengeLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id, onDelete: KeyAction.restrict)();
  IntColumn get exerciseType =>
      intEnum<ExerciseType>().withDefault(const Constant(0))();
  IntColumn get side => intEnum<ExerciseSide>().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  DateTimeColumn get loggedAt => dateTime().clientDefault(DateTime.now)();
}

// Singleton table: always exactly one row (id = 1) holding the streak counters.
// Updated incrementally on every completed session, never recomputed from scratch.
class StreakStats extends Table {
  IntColumn get id => integer()();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get currentStreakStartDate => dateTime().nullable()();
  DateTimeColumn get currentStreakEndDate => dateTime().nullable()();
  DateTimeColumn get longestStreakStartDate => dateTime().nullable()();
  DateTimeColumn get longestStreakEndDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
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
    ChallengeLogs,
    StreakStats,
  ],
)
class AppDatabase extends _$AppDatabase {
  new([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedStreakStats();
    },
    onUpgrade: _schemaUpgrade,
  );

  Future<void> _seedStreakStats() {
    return into(streakStats)
        .insertOnConflictUpdate(const StreakStatsCompanion(id: Value(1)));
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: "workout_tracker",
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}

extension Migrations on GeneratedDatabase {
  OnUpgrade get _schemaUpgrade => stepByStep(
    from1To2: (m, s) async {
      await m.addColumn(s.exercises, s.exercises.isBilateral);
      await m.addColumn(s.workoutExercises, s.workoutExercises.side);
      await m.addColumn(s.sessionExerciseLogs, s.sessionExerciseLogs.side);
    },
    from2To3: (m, s) async {
      await m.addColumn(s.workouts, s.workouts.kind);
      await m.createTable(s.challengeLogs);
    },
  );
}
