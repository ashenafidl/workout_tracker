import "package:workout_tracker/database/database.dart";

class StreakRepo {
  new(this._db);

  final AppDatabase _db;

  Stream<StreakStat?> watchStreakStats() {
    return (_db.select(
      _db.streakStats,
    )..where((s) => s.id.equals(1))).watchSingleOrNull();
  }
}
