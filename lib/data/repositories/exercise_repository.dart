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
}
