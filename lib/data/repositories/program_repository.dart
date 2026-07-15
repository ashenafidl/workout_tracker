import "package:drift/drift.dart";
import "package:workout_tracker/data/models/programs.dart";
import "package:workout_tracker/database/database.dart";

class ProgramRepository {
  ProgramRepository(this._db);

  final AppDatabase _db;

  Stream<List<ProgramWithWorkoutCount>> watchPrograms() {
    final query = _db.select(_db.programs)
      ..orderBy([(p) => OrderingTerm(expression: p.createdAt)]);

    return query.watch().asyncMap((programs) async {
      final results = <ProgramWithWorkoutCount>[];
      for (final program in programs) {
        final countQuery = _db.select(_db.workouts)
          ..where((w) => w.programId.equals(program.id));
        final workouts = await countQuery.get();
        results.add(
          ProgramWithWorkoutCount(
            program: program,
            workoutCount: workouts.length,
          ),
        );
      }
      return results;
    });
  }

  Future<int> createProgram({required String name}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception("Program name is required");
    }

    final companion = ProgramsCompanion.insert(name: trimmedName);
    return _db.into(_db.programs).insert(companion);
  }

  Future<void> updateProgram({required int id, required String name}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception("Program name is required");
    }

    await (_db.update(_db.programs)..where((program) => program.id.equals(id)))
        .write(ProgramsCompanion(name: Value(trimmedName)));
  }

  Future<void> deleteProgram(int id) async {
    await (_db.delete(
      _db.programs,
    )..where((program) => program.id.equals(id))).go();
  }
}
