import "package:drift/drift.dart";
import "package:workout_tracker/database/database.dart";

class ExerciseRepository {
  final AppDatabase _db;

  ExerciseRepository(this._db);

  Stream<int> watchExerciseCount() {
    final query = _db.exercises.count();
    return query.watchSingle();
  }

  Stream<List<Exercise>> watchAllExercises() {
    final query = _db.select(_db.exercises)
      ..orderBy([(e) => OrderingTerm(expression: e.name)]);

    return query.watch();
  }

  Future<void> addExercise({required String name, String? description}) async {
    final trimmedDescription = description?.trim();
    final companion = ExercisesCompanion.insert(
      name: name.trim(),
      description: Value(
        trimmedDescription?.isNotEmpty == true ? trimmedDescription : null,
      ),
    );

    await _db.into(_db.exercises).insert(companion);
  }

  Future<void> updateExercise({
    required int id,
    required String name,
    String? description,
  }) async {
    final trimmedDescription = description?.trim();
    final companion = ExercisesCompanion(
      name: Value(name.trim()),
      description: Value(
        trimmedDescription?.isNotEmpty == true ? trimmedDescription : null,
      ),
      updatedAt: Value(DateTime.now()),
    );

    await (_db.update(
      _db.exercises,
    )..where((tbl) => tbl.id.equals(id))).write(companion);
  }

  Future<void> deleteExercise(int id) async {
    await (_db.delete(_db.exercises)..where((tbl) => tbl.id.equals(id))).go();
  }
}
