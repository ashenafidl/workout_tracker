import "package:drift/drift.dart";
import "package:workout_tracker/database/database.dart";

class StreakService {
  new(this._db);

  final AppDatabase _db;

  static const int _singletonId = 1;

  Future<void> recordCompletedSession({int? excludeSessionId}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    await _db.transaction(() async {
      final stats = await _load();

      // Another session already landed on this calendar day, so this day is
      // already counted towards the streak.
      final alreadyCountedToday = await _hasCompletedSession(
        today,
        tomorrow,
        excludeSessionId: excludeSessionId,
      );
      if (alreadyCountedToday) return;

      var currentStreak = stats.currentStreak;
      var currentStreakStartDate = stats.currentStreakStartDate;
      var currentStreakEndDate = stats.currentStreakEndDate;
      var longestStreak = stats.longestStreak;
      var longestStreakStartDate = stats.longestStreakStartDate;
      var longestStreakEndDate = stats.longestStreakEndDate;

      final continued = await _hasCompletedSession(yesterday, today);
      if (continued) {
        currentStreak = currentStreak + 1;
        currentStreakStartDate ??= today;
        currentStreakEndDate = today;
      } else {
        // A day was missed: the streak that just ended is banked as the
        // previous streak before being compared against the longest one.
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
          longestStreakStartDate = currentStreakStartDate;
          longestStreakEndDate = currentStreakEndDate;
        }

        currentStreak = 1;
        currentStreakStartDate = today;
        currentStreakEndDate = today;
      }

      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
        longestStreakStartDate = currentStreakStartDate;
        longestStreakEndDate = currentStreakEndDate;
      }

      await _db
          .into(_db.streakStats)
          .insertOnConflictUpdate(
            StreakStatsCompanion(
              id: const Value(_singletonId),
              currentStreak: Value(currentStreak),
              longestStreak: Value(longestStreak),
              currentStreakStartDate: Value(currentStreakStartDate),
              currentStreakEndDate: Value(currentStreakEndDate),
              longestStreakStartDate: Value(longestStreakStartDate),
              longestStreakEndDate: Value(longestStreakEndDate),
            ),
          );
    });
  }

  Future<StreakStat> _load() {
    return (_db.select(
      _db.streakStats,
    )..where((s) => s.id.equals(_singletonId))).getSingle();
  }

  /// Whether a session was completed in the `[start, end)` window.
  Future<bool> _hasCompletedSession(
    DateTime start,
    DateTime end, {
    int? excludeSessionId,
  }) async {
    final query = _db.selectOnly(_db.workoutSessions)
      ..addColumns([_db.workoutSessions.id])
      ..where(
        _db.workoutSessions.completedAt.isBiggerOrEqualValue(start) &
            _db.workoutSessions.completedAt.isSmallerThanValue(end),
      );
    if (excludeSessionId != null) {
      query.where(_db.workoutSessions.id.equals(excludeSessionId).not());
    }

    return (await query.get()).isNotEmpty;
  }
}
