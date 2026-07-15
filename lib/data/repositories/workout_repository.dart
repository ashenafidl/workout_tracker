import "package:drift/drift.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/database/database.dart";

class WorkoutRepository {
  WorkoutRepository(this._db);

  final AppDatabase _db;

  Stream<List<WorkoutWithExercises>> watchWorkoutsForProgram(int programId) {
    final query = _db.select(_db.workouts)
      ..where((w) => w.programId.equals(programId))
      ..orderBy([(w) => OrderingTerm(expression: w.position)]);

    return query.watch().asyncMap((workouts) async {
      final results = <WorkoutWithExercises>[];
      for (final workout in workouts) {
        final weQuery =
            _db.select(_db.workoutExercises).join([
                innerJoin(
                  _db.exercises,
                  _db.exercises.id.equalsExp(_db.workoutExercises.exerciseId),
                ),
              ])
              ..where(_db.workoutExercises.workoutId.equals(workout.id))
              ..orderBy([
                OrderingTerm(expression: _db.workoutExercises.position),
              ]);

        final rows = await weQuery.get();
        final details = rows.map((row) {
          final exercise = row.readTable(_db.exercises);
          final we = row.readTable(_db.workoutExercises);
          return WorkoutExerciseDetail(
            exercise: exercise,
            reps: we.reps,
            position: we.position,
          );
        }).toList();

        results.add(WorkoutWithExercises(workout: workout, exercises: details));
      }
      return results;
    });
  }

  Future<void> addWorkout({
    required String programId,
    required String name,
    required int sets,
    required List<WorkoutExerciseInput> exercises,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception("Workout name is required");
    }

    final now = DateTime.now();

    await _db.transaction(() async {
      final workoutCompanion = WorkoutsCompanion.insert(
        programId: int.parse(programId),
        name: trimmedName,
        sets: sets,
        position: await _nextWorkoutPosition(programId),
        createdAt: Value(now),
        updatedAt: Value(now),
      );
      final workoutId = await _db.into(_db.workouts).insert(workoutCompanion);

      for (final input in exercises) {
        final weCompanion = WorkoutExercisesCompanion.insert(
          workoutId: workoutId,
          exerciseId: input.exerciseId,
          reps: input.reps,
          position: input.position,
        );
        await _db.into(_db.workoutExercises).insert(weCompanion);
      }
    });
  }

  Future<void> updateWorkout({
    required int workoutId,
    required String name,
    required int sets,
    required List<WorkoutExerciseInput> exercises,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception("Workout name is required");
    }

    await _db.transaction(() async {
      await (_db.update(
        _db.workouts,
      )..where((w) => w.id.equals(workoutId))).write(
        WorkoutsCompanion(
          name: Value(trimmedName),
          sets: Value(sets),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await (_db.delete(
        _db.workoutExercises,
      )..where((we) => we.workoutId.equals(workoutId))).go();

      for (final input in exercises) {
        final weCompanion = WorkoutExercisesCompanion.insert(
          workoutId: workoutId,
          exerciseId: input.exerciseId,
          reps: input.reps,
          position: input.position,
        );
        await _db.into(_db.workoutExercises).insert(weCompanion);
      }
    });
  }

  Future<void> deleteWorkout(int workoutId) async {
    await (_db.delete(_db.workouts)..where((w) => w.id.equals(workoutId))).go();
  }

  Future<void> reorderWorkouts(String programId, List<int> orderedIds) async {
    await _db.transaction(() async {
      for (int i = 0; i < orderedIds.length; i++) {
        await (_db.update(
          _db.workouts,
        )..where((w) => w.id.equals(orderedIds[i]))).write(
          WorkoutsCompanion(
            position: Value(i),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<int> _nextWorkoutPosition(String programId) async {
    final query = _db.select(_db.workouts)
      ..where((w) => w.programId.equals(int.parse(programId)))
      ..orderBy([
        (w) => OrderingTerm(expression: w.position, mode: OrderingMode.desc),
      ])
      ..limit(1);

    final rows = await query.get();
    if (rows.isEmpty) {
      return 0;
    }
    return rows.first.position + 1;
  }
}
