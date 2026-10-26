import "package:drift/drift.dart";
import "package:workout_tracker/database/database.dart";

class BodyWeightRepo {
  new(this._db);

  final AppDatabase _db;

  Stream<List<BodyWeightLog>> watchAll() {
    return (_db.select(
      _db.bodyWeightLogs,
    )..orderBy([(log) => OrderingTerm(expression: log.loggedAt)])).watch();
  }

  Future<BodyWeightLog?> getLatest() {
    return (_db.select(_db.bodyWeightLogs)
          ..orderBy([
            (log) =>
                OrderingTerm(expression: log.loggedAt, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> add({required double weightKg}) async {
    await _db
        .into(_db.bodyWeightLogs)
        .insert(BodyWeightLogsCompanion.insert(weightKg: weightKg));
  }

  Future<void> update({required int id, required double weightKg}) async {
    await (_db.update(_db.bodyWeightLogs)..where((log) => log.id.equals(id)))
        .write(BodyWeightLogsCompanion(weightKg: Value(weightKg)));
  }
}
