import "package:drift/drift.dart";
import "package:workout_tracker/data/models/programs.dart";
import "package:workout_tracker/database/database.dart";

class ProgramRepo {
  new(this._db);

  final AppDatabase _db;

  Stream<Program?> watchActiveProgram() {
    return (_db.select(
      _db.programs,
    )..where((program) => program.isActive.equals(true))).watchSingleOrNull();
  }

  Stream<List<ProgramWithWorkoutCount>> watchPrograms() {
    final count = _db.workouts.id.count();
    final query =
        _db.select(_db.programs).join([
            leftOuterJoin(
              _db.workouts,
              _db.workouts.programId.equalsExp(_db.programs.id),
            ),
          ])
          ..addColumns([count])
          ..groupBy([_db.programs.id])
          ..orderBy([OrderingTerm(expression: _db.programs.createdAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ProgramWithWorkoutCount(
          program: row.readTable(_db.programs),
          workoutCount: row.read(count) ?? 0,
        );
      }).toList();
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

  Future<void> setActiveProgram(int id) async {
    await _db.transaction(() async {
      final activeProgram = await (_db.select(
        _db.programs,
      )..where((p) => p.isActive.equals(true))).getSingleOrNull();

      if (activeProgram != null && activeProgram.id != id) {
        await (_db.update(_db.programs)
              ..where((p) => p.id.equals(activeProgram.id)))
            .write(const ProgramsCompanion(isActive: Value(false)));
      }

      await (_db.update(_db.programs)..where((p) => p.id.equals(id))).write(
        const ProgramsCompanion(isActive: Value(true)),
      );
    });
  }

  Future<int> getWorkoutCount(int id) async {
    final countExp = _db.workouts.id.count();

    final query = _db.selectOnly(_db.workouts)
      ..addColumns([countExp])
      ..where(_db.workouts.programId.equals(id));

    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }
}
