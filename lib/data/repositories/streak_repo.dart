import "package:workout_tracker/data/models/daily_activity.dart";
import "package:workout_tracker/data/repositories/session_repo.dart";
import "package:workout_tracker/database/database.dart";

class StreakRepo {
  new(this._db, this._sessionRepo);

  final AppDatabase _db;
  final SessionRepo _sessionRepo;

  Stream<StreakStat?> watchStreakStats() {
    return (_db.select(
      _db.streakStats,
    )..where((s) => s.id.equals(1))).watchSingleOrNull();
  }

  Stream<List<DailyActivity>> watchDailyActivity() {
    return _sessionRepo.watchSessionHistory().map((entries) {
      final activityByDay = <DateTime, _DailyActivityTotals>{};
      for (final entry in entries) {
        final completedAt = entry.session.completedAt!;
        final day = DateTime(
          completedAt.year,
          completedAt.month,
          completedAt.day,
        );
        final totals = activityByDay.putIfAbsent(day, _DailyActivityTotals.new);
        totals.workoutDuration += entry.durations.workout;
        totals.restDuration += entry.durations.rest;
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
}

class _DailyActivityTotals {
  Duration workoutDuration = Duration.zero;
  Duration restDuration = Duration.zero;
}
