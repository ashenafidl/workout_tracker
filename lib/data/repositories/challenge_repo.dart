import "package:drift/drift.dart";
import "package:workout_tracker/data/models/challenge.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/database/database.dart";

class ChallengeRepo {
  new(this._db);

  final AppDatabase _db;

  Future<int> getOrCreateTodaySession(
    int workoutId,
    int programId, {
    DateTime? since,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // One session per challenge per day, whether it is still open or has
    // already been marked done. Sessions started before [since] belong to a
    // previous program run and are ignored.
    final query = _db.select(_db.workoutSessions)
      ..where((session) {
        final base =
            session.workoutId.equals(workoutId) &
            session.startedAt.isBiggerOrEqualValue(today) &
            session.startedAt.isSmallerThanValue(tomorrow);
        if (since == null) return base;
        return base & session.startedAt.isBiggerOrEqualValue(since);
      })
      ..orderBy([
        (session) => OrderingTerm(
          expression: session.startedAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(1);

    final existing = await query.getSingleOrNull();
    if (existing != null) return existing.id;

    return _db
        .into(_db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            workoutId: workoutId,
            programId: programId,
            startedAt: now,
          ),
        );
  }

  Future<bool> isSessionCompleted(int sessionId) async {
    final query = _db.select(_db.workoutSessions)
      ..where((session) => session.id.equals(sessionId));
    final session = await query.getSingleOrNull();
    return session?.completedAt != null;
  }

  Future<void> logReps({
    required int sessionId,
    required int exerciseId,
    required ExerciseType exerciseType,
    required ExerciseSide? side,
    required int reps,
  }) async {
    await _db
        .into(_db.challengeLogs)
        .insert(
          ChallengeLogsCompanion.insert(
            sessionId: sessionId,
            exerciseId: exerciseId,
            exerciseType: Value(exerciseType),
            side: Value(side),
            reps: Value(reps),
          ),
        );
  }

  Future<void> logDuration({
    required int sessionId,
    required int exerciseId,
    required ExerciseType exerciseType,
    required ExerciseSide? side,
    required int durationSeconds,
  }) async {
    await _db
        .into(_db.challengeLogs)
        .insert(
          ChallengeLogsCompanion.insert(
            sessionId: sessionId,
            exerciseId: exerciseId,
            exerciseType: Value(exerciseType),
            side: Value(side),
            durationSeconds: Value(durationSeconds),
          ),
        );
  }

  Future<void> completeSession(int sessionId) async {
    await (_db.update(_db.workoutSessions)
          ..where((session) => session.id.equals(sessionId)))
        .write(WorkoutSessionsCompanion(completedAt: Value(DateTime.now())));
  }

  Stream<List<ChallengeExerciseProgress>> watchProgress(
    int sessionId,
    int workoutId,
  ) {
    final query =
        _db.select(_db.workoutExercises).join([
            innerJoin(
              _db.exercises,
              _db.exercises.id.equalsExp(_db.workoutExercises.exerciseId),
            ),
            leftOuterJoin(
              _db.challengeLogs,
              _db.challengeLogs.exerciseId.equalsExp(
                    _db.workoutExercises.exerciseId,
                  ) &
                  _db.challengeLogs.sessionId.equals(sessionId),
            ),
          ])
          ..where(_db.workoutExercises.workoutId.equals(workoutId))
          ..orderBy([OrderingTerm(expression: _db.workoutExercises.position)]);

    return query.watch().map((rows) {
      final grouped = <int, _ChallengeGrouping>{};
      final order = <int>[];

      for (final row in rows) {
        final workoutExercise = row.readTable(_db.workoutExercises);
        final exercise = row.readTable(_db.exercises);
        final grouping = grouped.putIfAbsent(workoutExercise.id, () {
          order.add(workoutExercise.id);
          return _ChallengeGrouping(
            workoutExercise: workoutExercise,
            exercise: exercise,
          );
        });

        final log = row.readTableOrNull(_db.challengeLogs);
        if (log != null) {
          grouping.logs.add(log);
        }
      }

      return [for (final id in order) ...grouped[id]!.toProgress()];
    });
  }

  /// Progress for today's challenge session, or an empty list when the
  /// challenge has not been started today.
  Stream<List<ChallengeExerciseProgress>> watchTodayProgress(int workoutId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final query = _db.select(_db.workoutSessions)
      ..where(
        (session) =>
            session.workoutId.equals(workoutId) &
            session.startedAt.isBiggerOrEqualValue(today) &
            session.startedAt.isSmallerThanValue(tomorrow),
      )
      ..orderBy([
        (session) => OrderingTerm(
          expression: session.startedAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(1);

    return query.watchSingleOrNull().asyncExpand((session) {
      if (session == null) {
        return Stream.value(const <ChallengeExerciseProgress>[]);
      }
      return watchProgress(session.id, workoutId);
    });
  }
}

class _ChallengeGrouping {
  new({required this.workoutExercise, required this.exercise});

  final WorkoutExercise workoutExercise;
  final Exercise exercise;
  final List<ChallengeLog> logs = [];

  List<ChallengeExerciseProgress> toProgress() {
    final side = workoutExercise.side;
    final performed = (!exercise.isBilateral || side == null)
        ? <ExerciseSide?>[null]
        : side.performedSides;

    final isReps = exercise.type == ExerciseType.reps;
    final repTargets = _splitTarget(
      isReps ? workoutExercise.targetReps : null,
      performed.length,
    );
    final durationTargets = _splitTarget(
      isReps ? null : workoutExercise.targetDurationSeconds,
      performed.length,
    );

    return [
      for (var i = 0; i < performed.length; i++)
        ChallengeExerciseProgress(
          workoutExerciseId: workoutExercise.id,
          exercise: exercise,
          side: performed[i],
          targetReps: repTargets?[i],
          targetDurationSeconds: durationTargets?[i],
          accumulatedReps: _sumReps(performed[i]),
          accumulatedDurationSeconds: _sumDuration(performed[i]),
        ),
    ];
  }

  int _sumReps(ExerciseSide? side) {
    return logs
        .where((log) => log.side == side)
        .fold(0, (sum, log) => sum + (log.reps ?? 0));
  }

  int _sumDuration(ExerciseSide? side) {
    return logs
        .where((log) => log.side == side)
        .fold(0, (sum, log) => sum + (log.durationSeconds ?? 0));
  }

  /// Splits a total target evenly across [parts], handing the remainder to the
  /// first parts so no reps/seconds are lost when splitting bilateral targets.
  List<int>? _splitTarget(int? total, int parts) {
    if (total == null) return null;
    if (parts <= 1) return [total];

    final base = total ~/ parts;
    final remainder = total % parts;
    return [for (var i = 0; i < parts; i++) base + (i < remainder ? 1 : 0)];
  }
}
