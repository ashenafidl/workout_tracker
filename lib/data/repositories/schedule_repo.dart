import "package:drift/drift.dart";
import "package:workout_tracker/data/models/workout_schedule.dart";
import "package:workout_tracker/database/database.dart";

class ScheduleRepo {
  new(this._db);

  final AppDatabase _db;

  Stream<WorkoutSchedule> watchSchedule() {
    final query = _db.select(_db.workoutScheduleChanges)
      ..orderBy([(row) => OrderingTerm(expression: row.effectiveFrom)]);

    return query.watch().map(_fromRows);
  }

  Future<WorkoutSchedule> load() async {
    final rows = await (_db.select(
      _db.workoutScheduleChanges,
    )..orderBy([(row) => OrderingTerm(expression: row.effectiveFrom)])).get();
    return _fromRows(rows);
  }

  Future<void> setWeekdays(Set<int> weekdays) async {
    if (weekdays.isEmpty) {
      throw ArgumentError.value(
        weekdays,
        "weekdays",
        "Pick at least one workout day",
      );
    }

    final effectiveToday = _dateOnly(DateTime.now());
    final currentSchedule = await load();
    final currentWeekdays = currentSchedule.weekdaysOn(effectiveToday);
    if (currentWeekdays == weekdays) {
      return;
    }

    await _db
        .into(_db.workoutScheduleChanges)
        .insertOnConflictUpdate(
          WorkoutScheduleChangesCompanion.insert(
            effectiveFrom: Value(effectiveToday),
            weekdayMask: Value(weekdayMaskFor(weekdays)),
          ),
        );
  }

  WorkoutSchedule _fromRows(List<WorkoutScheduleChange> rows) {
    if (rows.isEmpty) {
      return WorkoutSchedule([
        ScheduleChange(
          effectiveFrom: DateTime(2000, 1, 1),
          weekdays: {1, 2, 3, 4, 5, 6, 7},
        ),
      ]);
    }

    return WorkoutSchedule(
      rows
          .map(
            (row) => ScheduleChange(
              effectiveFrom: row.effectiveFrom,
              weekdays: weekdaysFromMask(row.weekdayMask),
            ),
          )
          .toList(),
    );
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
