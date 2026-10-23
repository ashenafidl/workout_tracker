import "package:drift/drift.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/database/database.dart";

class ExerciseRepo {
  new(this._db);

  final AppDatabase _db;

  Stream<int?> watchExerciseCount() {
    final query = _db.exercises.count();
    return query.watchSingleOrNull();
  }

  Future<List<ExerciseType>> getSupportedTypes(int exerciseId) async {
    final query = _db.select(_db.exerciseSupportedTypes)
      ..where((row) => row.exerciseId.equals(exerciseId))
      ..orderBy([(row) => OrderingTerm(expression: row.type)]);

    return (await query.get()).map((row) => row.type).toList();
  }

  Stream<List<ExerciseWithTypes>> watchAllExercisesWithTypes() {
    final query =
        _db.select(_db.exercises).join([
            leftOuterJoin(
              _db.exerciseSupportedTypes,
              _db.exerciseSupportedTypes.exerciseId.equalsExp(
                _db.exercises.id,
              ),
            ),
          ])
          ..orderBy([
            OrderingTerm(expression: _db.exercises.name),
            OrderingTerm(expression: _db.exerciseSupportedTypes.type),
          ]);

    return query.watch().map((rows) {
      final exercises = <int, _ExerciseGrouping>{};
      for (final row in rows) {
        final exercise = row.readTable(_db.exercises);
        final grouping = exercises.putIfAbsent(
          exercise.id,
          () => _ExerciseGrouping(exercise),
        );
        final supportedType = row.readTableOrNull(_db.exerciseSupportedTypes);
        if (supportedType != null) {
          grouping.supportedTypes.add(supportedType.type);
        }
      }

      return exercises.values.map((grouping) {
        return ExerciseWithTypes(
          exercise: grouping.exercise,
          supportedTypes: grouping.supportedTypes,
        );
      }).toList();
    });
  }

  Future<int> addExercise({
    required String name,
    String? description,
    required List<ExerciseType> types,
    bool isBilateral = false,
  }) async {
    if (types.isEmpty) {
      throw ArgumentError.value(types, "types", "Select at least one type");
    }
    final trimmedDescription = description?.trim();
    final companion = ExercisesCompanion.insert(
      name: name.trim(),
      description: Value(
        trimmedDescription?.isNotEmpty == true ? trimmedDescription : null,
      ),
      isBilateral: Value(isBilateral),
    );

    return _db.transaction(() async {
      final exerciseId = await _db.into(_db.exercises).insert(companion);
      for (final type in types.toSet()) {
        await _db
            .into(_db.exerciseSupportedTypes)
            .insert(
              ExerciseSupportedTypesCompanion.insert(
                exerciseId: exerciseId,
                type: type,
              ),
            );
      }
      return exerciseId;
    });
  }

  Future<void> updateExercise({
    required int id,
    required String name,
    String? description,
    required List<ExerciseType> types,
    required bool isBilateral,
  }) async {
    if (types.isEmpty) {
      throw ArgumentError.value(types, "types", "Select at least one type");
    }
    final trimmedDescription = description?.trim();
    final companion = ExercisesCompanion(
      name: Value(name.trim()),
      description: Value(
        trimmedDescription?.isNotEmpty == true ? trimmedDescription : null,
      ),
      isBilateral: Value(isBilateral),
      updatedAt: Value(DateTime.now()),
    );

    await _db.transaction(() async {
      await (_db.update(
        _db.exercises,
      )..where((tbl) => tbl.id.equals(id))).write(companion);
      await (_db.delete(
        _db.exerciseSupportedTypes,
      )..where((row) => row.exerciseId.equals(id))).go();
      for (final type in types.toSet()) {
        await _db
            .into(_db.exerciseSupportedTypes)
            .insert(
              ExerciseSupportedTypesCompanion.insert(
                exerciseId: id,
                type: type,
              ),
            );
      }
    });
  }

  Future<void> addSupportedType(int exerciseId, ExerciseType type) async {
    await _db
        .into(_db.exerciseSupportedTypes)
        .insertOnConflictUpdate(
          ExerciseSupportedTypesCompanion.insert(
            exerciseId: exerciseId,
            type: type,
          ),
        );
  }

  Future<void> removeSupportedType(int exerciseId, ExerciseType type) async {
    await _db.transaction(() async {
      final supportedTypes = await getSupportedTypes(exerciseId);
      if (!supportedTypes.contains(type)) {
        return;
      }
      if (supportedTypes.length == 1) {
        throw StateError("An exercise must support at least one type");
      }
      await (_db.delete(_db.exerciseSupportedTypes)
            ..where(
              (row) =>
                  row.exerciseId.equals(exerciseId) &
                      row.type.equals(type.index),
            ))
          .go();
    });
  }

  Future<void> deleteExercise(int id) async {
    await (_db.delete(_db.exercises)..where((tbl) => tbl.id.equals(id))).go();
  }
}

class _ExerciseGrouping {
  new(this.exercise);

  final Exercise exercise;
  final List<ExerciseType> supportedTypes = [];
}
