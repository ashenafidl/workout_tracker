import "dart:convert";

import "package:drift/drift.dart";
import "package:file_picker/file_picker.dart";
import "package:workout_tracker/data/services/shared_preference_service.dart";
import "package:workout_tracker/database/database.dart";

const _backupFormat = "workout_tracker_backup";
const _backupVersion = 1;
const _autoIncrementTables = [
  "exercises",
  "programs",
  "workouts",
  "workout_exercises",
  "workout_sessions",
  "session_circuits",
  "session_exercise_logs",
  "challenge_logs",
  "body_weight_logs",
];
const _databaseTables = {
  "exercises",
  "exerciseSupportedTypes",
  "programs",
  "workouts",
  "workoutExercises",
  "workoutSessions",
  "sessionCircuits",
  "sessionExerciseLogs",
  "challengeLogs",
  "streakStats",
  "bodyWeightLogs",
};
const _dateFields = {
  "createdAt",
  "updatedAt",
  "startedAt",
  "completedAt",
  "loggedAt",
  "currentStreakStartDate",
  "currentStreakEndDate",
  "longestStreakStartDate",
  "longestStreakEndDate",
};
const _jsonSerializer = ValueSerializer.defaults(
  serializeDateTimeValuesAsString: true,
);

class BackupException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupContents {
  // The concrete class name is required here to keep this constructor private.
  // ignore: unnecessary_type_name_in_constructor
  const BackupContents._({
    required this.preferences,
    required this.exercises,
    required this.exerciseSupportedTypes,
    required this.programs,
    required this.workouts,
    required this.workoutExercises,
    required this.workoutSessions,
    required this.sessionCircuits,
    required this.sessionExerciseLogs,
    required this.challengeLogs,
    required this.streakStats,
    required this.bodyWeightLogs,
  });

  final Map<String, int> preferences;
  final List<Exercise> exercises;
  final List<ExerciseSupportedType> exerciseSupportedTypes;
  final List<Program> programs;
  final List<Workout> workouts;
  final List<WorkoutExercise> workoutExercises;
  final List<WorkoutSession> workoutSessions;
  final List<SessionCircuit> sessionCircuits;
  final List<SessionExerciseLog> sessionExerciseLogs;
  final List<ChallengeLog> challengeLogs;
  final List<StreakStat> streakStats;
  final List<BodyWeightLog> bodyWeightLogs;

  int get recordCount =>
      exercises.length +
      exerciseSupportedTypes.length +
      programs.length +
      workouts.length +
      workoutExercises.length +
      workoutSessions.length +
      sessionCircuits.length +
      sessionExerciseLogs.length +
      challengeLogs.length +
      streakStats.length +
      bodyWeightLogs.length;

  String get summary =>
      "$recordCount database records and ${preferences.length} preferences";
}

class BackupService {
  const new(this._database, this._preferences);

  final AppDatabase _database;
  final SharedPreferenceService _preferences;

  Future<bool> exportBackup() async {
    final exportedAt = DateTime.now().toUtc();
    final json = await _createBackupJson(exportedAt);
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(json)));
    final savedUri = await FilePicker.saveFile(
      dialogTitle: "Save workout tracker backup",
      fileName:
          "workout_tracker_backup_"
          "${exportedAt.toIso8601String().replaceAll(":", "-")}.json",
      bytes: bytes,
      mimeType: "application/json",
    );
    return savedUri != null;
  }

  Future<BackupContents?> selectBackup() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ["json"],
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return parseBackupBytes(bytes);
  }

  BackupContents parseBackupBytes(Uint8List bytes) => _parseBackup(bytes);

  Future<void> restoreBackup(BackupContents backup) async {
    final previousPreferences = _preferences.exportBackupPreferences();
    try {
      await _preferences.replaceBackupPreferences(backup.preferences);
      await _database.transaction(() async {
        await _clearDatabase();
        await _insertBackup(backup);
      });
    } catch (error) {
      try {
        await _preferences.replaceBackupPreferences(previousPreferences);
      } catch (recoveryError) {
        throw BackupException(
          "Restore failed: $error. Preference recovery also failed: "
          "$recoveryError",
        );
      }
      throw BackupException(
        "Restore failed. Existing preferences were recovered: $error",
      );
    }
  }

  Future<Map<String, Object?>> _createBackupJson(DateTime exportedAt) async {
    final databaseRecords = await _database.transaction(() async {
      return <String, Object?>{
        "exercises": (await _database.select(_database.exercises).get())
            .map((row) => row.toJson(serializer: _jsonSerializer))
            .toList(),
        "exerciseSupportedTypes":
            (await _database.select(_database.exerciseSupportedTypes).get())
                .map((row) => row.toJson(serializer: _jsonSerializer))
                .toList(),
        "programs": (await _database.select(_database.programs).get())
            .map((row) => row.toJson(serializer: _jsonSerializer))
            .toList(),
        "workouts": (await _database.select(_database.workouts).get())
            .map((row) => row.toJson(serializer: _jsonSerializer))
            .toList(),
        "workoutExercises":
            (await _database.select(_database.workoutExercises).get())
                .map((row) => row.toJson(serializer: _jsonSerializer))
                .toList(),
        "workoutSessions":
            (await _database.select(_database.workoutSessions).get())
                .map((row) => row.toJson(serializer: _jsonSerializer))
                .toList(),
        "sessionCircuits":
            (await _database.select(_database.sessionCircuits).get())
                .map((row) => row.toJson(serializer: _jsonSerializer))
                .toList(),
        "sessionExerciseLogs":
            (await _database.select(_database.sessionExerciseLogs).get())
                .map((row) => row.toJson(serializer: _jsonSerializer))
                .toList(),
        "challengeLogs": (await _database.select(_database.challengeLogs).get())
            .map((row) => row.toJson(serializer: _jsonSerializer))
            .toList(),
        "streakStats": (await _database.select(_database.streakStats).get())
            .map((row) => row.toJson(serializer: _jsonSerializer))
            .toList(),
        "bodyWeightLogs":
            (await _database.select(_database.bodyWeightLogs).get())
                .map((row) => row.toJson(serializer: _jsonSerializer))
                .toList(),
      };
    });

    final preferences = _preferences.exportBackupPreferences();
    return {
      "format": _backupFormat,
      "backupVersion": _backupVersion,
      "databaseSchemaVersion": _database.schemaVersion,
      "exportedAt": exportedAt.toIso8601String(),
      "database": databaseRecords,
      "preferences": {
        for (final entry in preferences.entries)
          entry.key: {"type": "int", "value": entry.value},
      },
    };
  }

  BackupContents _parseBackup(Uint8List bytes) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException catch (error) {
      throw BackupException("The selected file is not valid JSON: $error");
    }
    final root = _asMap(decoded, "backup");
    _requireKeys(root, const {
      "format",
      "backupVersion",
      "databaseSchemaVersion",
      "exportedAt",
      "database",
      "preferences",
    }, "backup");
    if (root["format"] != _backupFormat) {
      throw const BackupException("This is not a Workout Tracker backup.");
    }
    if (root["backupVersion"] is! int ||
        root["backupVersion"] != _backupVersion) {
      throw BackupException(
        "Unsupported backup format version: ${root["backupVersion"]}.",
      );
    }
    if (root["databaseSchemaVersion"] is! int ||
        root["databaseSchemaVersion"] != _database.schemaVersion) {
      throw BackupException(
        "This backup uses database schema "
        "${root["databaseSchemaVersion"]}; this app supports "
        "${_database.schemaVersion}.",
      );
    }
    _readDate(root["exportedAt"], "exportedAt");

    final rawDatabase = _asMap(root["database"], "database");
    _requireKeys(rawDatabase, _databaseTables, "database");

    final exercises = _readRows(rawDatabase["exercises"], "exercises", const {
      "id",
      "name",
      "description",
      "isBilateral",
      "createdAt",
      "updatedAt",
    }, Exercise.fromJson);
    final exerciseSupportedTypes = _readRows(
      rawDatabase["exerciseSupportedTypes"],
      "exerciseSupportedTypes",
      const {"exerciseId", "type"},
      ExerciseSupportedType.fromJson,
    );
    final programs = _readRows(rawDatabase["programs"], "programs", const {
      "id",
      "name",
      "isActive",
      "createdAt",
    }, Program.fromJson);
    final workouts = _readRows(rawDatabase["workouts"], "workouts", const {
      "id",
      "programId",
      "name",
      "kind",
      "sets",
      "restDurationSeconds",
      "position",
      "createdAt",
      "updatedAt",
    }, Workout.fromJson);
    final workoutExercises = _readRows(
      rawDatabase["workoutExercises"],
      "workoutExercises",
      const {
        "id",
        "workoutId",
        "exerciseId",
        "position",
        "type",
        "side",
        "targetReps",
        "targetDurationSeconds",
      },
      WorkoutExercise.fromJson,
    );
    final workoutSessions = _readRows(
      rawDatabase["workoutSessions"],
      "workoutSessions",
      const {"id", "workoutId", "programId", "startedAt", "completedAt"},
      WorkoutSession.fromJson,
    );
    final sessionCircuits = _readRows(
      rawDatabase["sessionCircuits"],
      "sessionCircuits",
      const {"id", "sessionId", "circuitNumber", "startedAt", "completedAt"},
      SessionCircuit.fromJson,
    );
    final sessionExerciseLogs = _readRows(
      rawDatabase["sessionExerciseLogs"],
      "sessionExerciseLogs",
      const {
        "id",
        "circuitId",
        "exerciseId",
        "position",
        "exerciseType",
        "side",
        "targetReps",
        "actualReps",
        "targetDurationSeconds",
        "actualDurationSeconds",
        "startedAt",
        "completedAt",
      },
      SessionExerciseLog.fromJson,
    );
    final challengeLogs = _readRows(
      rawDatabase["challengeLogs"],
      "challengeLogs",
      const {
        "id",
        "sessionId",
        "exerciseId",
        "exerciseType",
        "side",
        "reps",
        "durationSeconds",
        "loggedAt",
      },
      ChallengeLog.fromJson,
    );
    final streakStats = _readRows(
      rawDatabase["streakStats"],
      "streakStats",
      const {
        "id",
        "currentStreak",
        "longestStreak",
        "currentStreakStartDate",
        "currentStreakEndDate",
        "longestStreakStartDate",
        "longestStreakEndDate",
      },
      StreakStat.fromJson,
    );
    final bodyWeightLogs = _readRows(
      rawDatabase["bodyWeightLogs"],
      "bodyWeightLogs",
      const {"id", "weightKg", "loggedAt"},
      BodyWeightLog.fromJson,
    );
    final preferences = _readPreferences(root["preferences"]);

    _validateDateStrings(rawDatabase);
    _validateRows(
      exercises: exercises,
      exerciseSupportedTypes: exerciseSupportedTypes,
      programs: programs,
      workouts: workouts,
      workoutExercises: workoutExercises,
      workoutSessions: workoutSessions,
      sessionCircuits: sessionCircuits,
      sessionExerciseLogs: sessionExerciseLogs,
      challengeLogs: challengeLogs,
      streakStats: streakStats,
    );

    return BackupContents._(
      preferences: Map.unmodifiable(preferences),
      exercises: List.unmodifiable(exercises),
      exerciseSupportedTypes: List.unmodifiable(exerciseSupportedTypes),
      programs: List.unmodifiable(programs),
      workouts: List.unmodifiable(workouts),
      workoutExercises: List.unmodifiable(workoutExercises),
      workoutSessions: List.unmodifiable(workoutSessions),
      sessionCircuits: List.unmodifiable(sessionCircuits),
      sessionExerciseLogs: List.unmodifiable(sessionExerciseLogs),
      challengeLogs: List.unmodifiable(challengeLogs),
      streakStats: List.unmodifiable(streakStats),
      bodyWeightLogs: List.unmodifiable(bodyWeightLogs),
    );
  }

  Map<String, int> _readPreferences(Object? raw) {
    final preferences = _asMap(raw, "preferences");
    final result = <String, int>{};
    for (final entry in preferences.entries) {
      _validatePreferenceKey(entry.key);
      final value = _asMap(entry.value, "preferences.${entry.key}");
      _requireKeys(value, const {"type", "value"}, "preferences.${entry.key}");
      if (value["type"] != "int" || value["value"] is! int) {
        throw BackupException(
          "Preference '${entry.key}' must have type 'int' and an integer value.",
        );
      }
      result[entry.key] = value["value"] as int;
    }
    return result;
  }

  void _validatePreferenceKey(String key) {
    if (!_preferences.isBackupPreferenceKey(key)) {
      throw BackupException(
        "Preference '$key' is outside the supported backup scope.",
      );
    }
    try {
      _preferences.validateBackupPreferenceKey(key);
    } on StateError catch (error) {
      throw BackupException("Preference '$key' is invalid: $error");
    }
  }

  void _validateDateStrings(Map<String, Object?> database) {
    for (final tableEntry in database.entries) {
      final rows = tableEntry.value as List<Object?>;
      for (var index = 0; index < rows.length; index++) {
        final row = rows[index] as Map<String, Object?>;
        for (final field in _dateFields) {
          if (!row.containsKey(field)) continue;
          final value = row[field];
          if (value == null && _isNullableDateField(field)) {
            continue;
          }
          if (value is! String) {
            throw BackupException(
              "${tableEntry.key}[$index].$field must be an ISO-8601 string.",
            );
          }
          _readDate(value, "${tableEntry.key}[$index].$field");
        }
      }
    }
  }

  bool _isNullableDateField(String field) =>
      field == "completedAt" ||
      field == "currentStreakStartDate" ||
      field == "currentStreakEndDate" ||
      field == "longestStreakStartDate" ||
      field == "longestStreakEndDate";

  void _validateRows({
    required List<Exercise> exercises,
    required List<ExerciseSupportedType> exerciseSupportedTypes,
    required List<Program> programs,
    required List<Workout> workouts,
    required List<WorkoutExercise> workoutExercises,
    required List<WorkoutSession> workoutSessions,
    required List<SessionCircuit> sessionCircuits,
    required List<SessionExerciseLog> sessionExerciseLogs,
    required List<ChallengeLog> challengeLogs,
    required List<StreakStat> streakStats,
  }) {
    _requireUnique(exercises.map((row) => row.id), "exercises.id");
    _requireUnique(programs.map((row) => row.id), "programs.id");
    _requireUnique(workouts.map((row) => row.id), "workouts.id");
    _requireUnique(
      workoutExercises.map((row) => row.id),
      "workoutExercises.id",
    );
    _requireUnique(workoutSessions.map((row) => row.id), "workoutSessions.id");
    _requireUnique(sessionCircuits.map((row) => row.id), "sessionCircuits.id");
    _requireUnique(
      sessionExerciseLogs.map((row) => row.id),
      "sessionExerciseLogs.id",
    );
    _requireUnique(challengeLogs.map((row) => row.id), "challengeLogs.id");
    _requireUnique(streakStats.map((row) => row.id), "streakStats.id");

    final exerciseIds = exercises.map((row) => row.id).toSet();
    final programIds = programs.map((row) => row.id).toSet();
    final workoutIds = workouts.map((row) => row.id).toSet();
    final sessionIds = workoutSessions.map((row) => row.id).toSet();
    final circuitIds = sessionCircuits.map((row) => row.id).toSet();
    _requireReferences(
      exerciseSupportedTypes.map((row) => row.exerciseId),
      exerciseIds,
      "exerciseSupportedTypes.exerciseId",
    );
    _requireReferences(
      workouts.map((row) => row.programId),
      programIds,
      "workouts.programId",
    );
    _requireReferences(
      workoutExercises.map((row) => row.workoutId),
      workoutIds,
      "workoutExercises.workoutId",
    );
    _requireReferences(
      workoutExercises.map((row) => row.exerciseId),
      exerciseIds,
      "workoutExercises.exerciseId",
    );
    _requireReferences(
      workoutSessions.map((row) => row.workoutId),
      workoutIds,
      "workoutSessions.workoutId",
    );
    _requireReferences(
      workoutSessions.map((row) => row.programId),
      programIds,
      "workoutSessions.programId",
    );
    _requireReferences(
      sessionCircuits.map((row) => row.sessionId),
      sessionIds,
      "sessionCircuits.sessionId",
    );
    _requireReferences(
      sessionExerciseLogs.map((row) => row.circuitId),
      circuitIds,
      "sessionExerciseLogs.circuitId",
    );
    _requireReferences(
      sessionExerciseLogs.map((row) => row.exerciseId),
      exerciseIds,
      "sessionExerciseLogs.exerciseId",
    );
    _requireReferences(
      challengeLogs.map((row) => row.sessionId),
      sessionIds,
      "challengeLogs.sessionId",
    );
    _requireReferences(
      challengeLogs.map((row) => row.exerciseId),
      exerciseIds,
      "challengeLogs.exerciseId",
    );

    _requireUnique(
      exerciseSupportedTypes.map(
        (row) => "${row.exerciseId}:${row.type.index}",
      ),
      "exerciseSupportedTypes.(exerciseId,type)",
    );
    if (streakStats.length != 1 || streakStats.single.id != 1) {
      throw const BackupException(
        "streakStats must contain exactly the singleton row with id 1.",
      );
    }
    if (programs.where((row) => row.isActive).length > 1) {
      throw const BackupException(
        "The backup contains more than one active program.",
      );
    }
    _requireValidNames(exercises.map((row) => row.name), "exercises.name");
    _requireValidNames(programs.map((row) => row.name), "programs.name");
    _requireValidNames(workouts.map((row) => row.name), "workouts.name");
  }

  void _requireValidNames(Iterable<String> names, String field) {
    for (final name in names) {
      if (name.isEmpty || name.length > 100) {
        throw BackupException("$field must contain 1 to 100 characters.");
      }
    }
  }

  void _requireUnique<T>(Iterable<T> values, String field) {
    final seen = <T>{};
    for (final value in values) {
      if (!seen.add(value)) {
        throw BackupException(
          "The backup contains duplicate values for $field.",
        );
      }
    }
  }

  void _requireReferences(
    Iterable<int> foreignKeys,
    Set<int> targetIds,
    String field,
  ) {
    for (final id in foreignKeys) {
      if (!targetIds.contains(id)) {
        throw BackupException("The backup has an invalid reference in $field.");
      }
    }
  }

  Future<void> _clearDatabase() async {
    await _database.delete(_database.sessionExerciseLogs).go();
    await _database.delete(_database.challengeLogs).go();
    await _database.delete(_database.sessionCircuits).go();
    await _database.delete(_database.workoutSessions).go();
    await _database.delete(_database.workoutExercises).go();
    await _database.delete(_database.exerciseSupportedTypes).go();
    await _database.delete(_database.workouts).go();
    await _database.delete(_database.programs).go();
    await _database.delete(_database.exercises).go();
    await _database.delete(_database.streakStats).go();
    await _database.delete(_database.bodyWeightLogs).go();
    final names = _autoIncrementTables.map((name) => "'$name'").join(", ");
    await _database.customStatement(
      "DELETE FROM sqlite_sequence WHERE name IN ($names)",
    );
  }

  Future<void> _insertBackup(BackupContents backup) async {
    await _database.batch((batch) {
      batch.insertAll(_database.exercises, backup.exercises);
      batch.insertAll(_database.programs, backup.programs);
      batch.insertAll(
        _database.exerciseSupportedTypes,
        backup.exerciseSupportedTypes,
      );
      batch.insertAll(_database.workouts, backup.workouts);
      batch.insertAll(_database.workoutExercises, backup.workoutExercises);
      batch.insertAll(_database.workoutSessions, backup.workoutSessions);
      batch.insertAll(_database.sessionCircuits, backup.sessionCircuits);
      batch.insertAll(
        _database.sessionExerciseLogs,
        backup.sessionExerciseLogs,
      );
      batch.insertAll(_database.challengeLogs, backup.challengeLogs);
      batch.insertAll(_database.streakStats, backup.streakStats);
      batch.insertAll(_database.bodyWeightLogs, backup.bodyWeightLogs);
    });
  }
}

List<T> _readRows<T>(
  Object? raw,
  String table,
  Set<String> fields,
  T Function(Map<String, dynamic>, {ValueSerializer? serializer}) decode,
) {
  if (raw is! List<Object?>) {
    throw BackupException("database.$table must be an array.");
  }
  final rows = <T>[];
  for (var index = 0; index < raw.length; index++) {
    final row = raw[index];
    if (row is! Map<String, Object?>) {
      throw BackupException("database.$table[$index] must be an object.");
    }
    try {
      _requireKeys(row, fields, "database.$table[$index]");
      rows.add(
        decode(Map<String, dynamic>.from(row), serializer: _jsonSerializer),
      );
    } on BackupException {
      rethrow;
    } on Object catch (error) {
      throw BackupException(
        "database.$table[$index] contains invalid data: $error",
      );
    }
  }
  return rows;
}

Map<String, Object?> _asMap(Object? value, String path) {
  if (value is Map<String, Object?>) return value;
  throw BackupException("$path must be a JSON object.");
}

void _requireKeys(
  Map<String, Object?> value,
  Set<String> expected,
  String path,
) {
  if (value.keys.toSet().difference(expected).isNotEmpty ||
      expected.difference(value.keys.toSet()).isNotEmpty) {
    throw BackupException("$path has missing or unsupported fields.");
  }
}

DateTime _readDate(Object? value, String path) {
  if (value is! String) {
    throw BackupException("$path must be an ISO-8601 string.");
  }
  try {
    return DateTime.parse(value);
  } on FormatException {
    throw BackupException("$path is not a valid ISO-8601 date.");
  }
}
