import "package:workout_tracker/data/models/stats.dart";
import "package:workout_tracker/database/database.dart";

class StatsRepo {
  new(this._db);

  final AppDatabase _db;

  Future<StatsSnapshot> loadStats(List<WorkoutSession> sessions) async {
    final sessionIds = sessions.map((session) => session.id).toList();

    final circuits = sessionIds.isEmpty
        ? <SessionCircuit>[]
        : await (_db.select(
            _db.sessionCircuits,
          )..where((circuit) => circuit.sessionId.isIn(sessionIds))).get();
    final circuitIds = circuits.map((circuit) => circuit.id).toList();
    final exerciseLogs = circuitIds.isEmpty
        ? <SessionExerciseLog>[]
        : await (_db.select(
            _db.sessionExerciseLogs,
          )..where((log) => log.circuitId.isIn(circuitIds))).get();
    final challengeLogs = sessionIds.isEmpty
        ? <ChallengeLog>[]
        : await (_db.select(
            _db.challengeLogs,
          )..where((log) => log.sessionId.isIn(sessionIds))).get();

    final frequencies = <int, int>{};
    var totalReps = 0;
    for (final log in exerciseLogs) {
      frequencies.update(
        log.exerciseId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      totalReps += log.actualReps ?? log.targetReps ?? 0;
    }
    for (final log in challengeLogs) {
      frequencies.update(
        log.exerciseId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      totalReps += log.reps ?? 0;
    }

    final durationsByWorkout = <int, List<Duration>>{};
    final workoutsByWeekday = List<int>.filled(7, 0);
    var totalDuration = Duration.zero;
    var weekdayWorkouts = 0;
    var weekendWorkouts = 0;
    for (final session in sessions) {
      final completedAt = session.completedAt!;
      final duration = completedAt.difference(session.startedAt);
      totalDuration += duration;
      durationsByWorkout.putIfAbsent(session.workoutId, () => []).add(duration);
      workoutsByWeekday[completedAt.weekday - 1]++;
      if (completedAt.weekday <= DateTime.friday) {
        weekdayWorkouts++;
      } else {
        weekendWorkouts++;
      }
    }

    return StatsSnapshot(
      totalWorkouts: sessions.length,
      totalCircuits: circuits.length,
      totalReps: totalReps,
      totalDuration: totalDuration,
      workoutsByWeekday: workoutsByWeekday,
      weekdayWorkouts: weekdayWorkouts,
      weekendWorkouts: weekendWorkouts,
    );
  }
}
