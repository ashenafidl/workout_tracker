import "package:drift/drift.dart";
import "package:workout_tracker/data/repositories/schedule_repo.dart";
import "package:workout_tracker/database/database.dart";

class StreakService {
  new(this._db, this._scheduleRepo);

  final AppDatabase _db;
  final ScheduleRepo _scheduleRepo;

  static const int _singletonId = 1;

  Future<void> recordCompletedSession({int? excludeSessionId}) async {
    final today = _dateOnly(DateTime.now());

    await _db.transaction(() async {
      final stats = await _load();
      final currentEndDate = stats.currentStreakEndDate;
      if (currentEndDate != null && _dateOnly(currentEndDate) == today) {
        return;
      }

      final schedule = await _scheduleRepo.load();
      final previousScheduledDay = schedule.previousScheduledDay(today);
      var currentStreak = stats.currentStreak;
      var currentStreakStartDate = stats.currentStreakStartDate;
      var currentStreakEndDate = stats.currentStreakEndDate;
      var longestStreak = stats.longestStreak;
      var longestStreakStartDate = stats.longestStreakStartDate;
      var longestStreakEndDate = stats.longestStreakEndDate;

      final lastCountedDay = currentStreakEndDate == null
          ? null
          : _dateOnly(currentStreakEndDate);
      final continued =
          lastCountedDay != null &&
          previousScheduledDay != null &&
          (lastCountedDay == previousScheduledDay ||
              (lastCountedDay.isAfter(previousScheduledDay) &&
                  !schedule.hasScheduledDayBetween(lastCountedDay, today)));

      if (continued) {
        currentStreak += 1;
        currentStreakStartDate ??= today;
        currentStreakEndDate = today;
      } else {
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

  Future<StreakStat> _load() async {
    final query = _db.select(_db.streakStats)
      ..where((s) => s.id.equals(_singletonId));
    final stats = await query.getSingleOrNull();
    if (stats != null) return stats;

    await _db
        .into(_db.streakStats)
        .insert(
          const StreakStatsCompanion(id: Value(_singletonId)),
          mode: InsertMode.insertOrIgnore,
        );
    return query.getSingle();
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
