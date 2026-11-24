import "package:workout_tracker/data/models/session_history.dart";
import "package:workout_tracker/data/models/stats.dart";

class StatsRepo {
  new();

  Future<StatsSnapshot> loadStats(List<SessionHistoryEntry> sessions) async {
    final durationsByWorkout = <int, List<Duration>>{};
    final workoutsByWeekday = List<int>.filled(7, 0);
    var totalDuration = Duration.zero;
    var weekdayWorkouts = 0;
    var weekendWorkouts = 0;
    for (final session in sessions) {
      final completedAt = session.session.completedAt!;
      final duration = session.duration;
      totalDuration += duration;
      durationsByWorkout
          .putIfAbsent(session.session.workoutId, () => [])
          .add(duration);
      workoutsByWeekday[completedAt.weekday - 1]++;
      if (completedAt.weekday <= DateTime.friday) {
        weekdayWorkouts++;
      } else {
        weekendWorkouts++;
      }
    }

    return StatsSnapshot(
      totalWorkouts: sessions.length,
      totalDuration: totalDuration,
      workoutsByWeekday: workoutsByWeekday,
      weekdayWorkouts: weekdayWorkouts,
      weekendWorkouts: weekendWorkouts,
    );
  }
}
