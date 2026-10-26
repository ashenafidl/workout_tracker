import "package:drift/drift.dart";
import "package:workout_tracker/data/models/daily_activity.dart";
import "package:workout_tracker/database/database.dart";

class StreakRepo {
  new(this._db);

  final AppDatabase _db;

  Stream<StreakStat?> watchStreakStats() {
    return (_db.select(
      _db.streakStats,
    )..where((s) => s.id.equals(1))).watchSingleOrNull();
  }

  Stream<List<DailyActivity>> watchDailyActivity() {
    final query = _db.select(_db.workoutSessions).join([
      leftOuterJoin(
        _db.sessionCircuits,
        _db.sessionCircuits.sessionId.equalsExp(_db.workoutSessions.id),
      ),
    ])..where(_db.workoutSessions.completedAt.isNotNull());

    return query.watch().map((rows) {
      final sessions = <int, _SessionActivity>{};
      for (final row in rows) {
        final session = row.readTable(_db.workoutSessions);
        final activity = sessions.putIfAbsent(
          session.id,
          () => _SessionActivity(session),
        );
        final circuit = row.readTableOrNull(_db.sessionCircuits);
        if (circuit != null) activity.circuits.add(circuit);
      }

      final activityByDay = <DateTime, _DailyActivityTotals>{};
      for (final activity in sessions.values) {
        final session = activity.session;
        final completedAt = session.completedAt!;
        final day = DateTime(
          completedAt.year,
          completedAt.month,
          completedAt.day,
        );
        final totalDuration = completedAt.difference(session.startedAt);
        final restDuration = _restDuration(activity.circuits);
        final totals = activityByDay.putIfAbsent(day, _DailyActivityTotals.new);
        totals.restDuration += restDuration;
        totals.workoutDuration += totalDuration - restDuration;
      }

      return activityByDay.entries
          .map(
            (entry) => DailyActivity(
              date: entry.key,
              workoutDuration: entry.value.workoutDuration,
              restDuration: entry.value.restDuration,
            ),
          )
          .toList();
    });
  }

  Duration _restDuration(List<SessionCircuit> circuits) {
    circuits.sort((a, b) => a.circuitNumber.compareTo(b.circuitNumber));

    var restDuration = Duration.zero;
    for (var index = 0; index < circuits.length - 1; index++) {
      final completedAt = circuits[index].completedAt;
      if (completedAt == null) continue;

      final gap = circuits[index + 1].startedAt.difference(completedAt);
      if (gap > Duration.zero) restDuration += gap;
    }
    return restDuration;
  }
}

class _SessionActivity {
  new(this.session);

  final WorkoutSession session;
  final List<SessionCircuit> circuits = [];
}

class _DailyActivityTotals {
  Duration workoutDuration = Duration.zero;
  Duration restDuration = Duration.zero;
}
