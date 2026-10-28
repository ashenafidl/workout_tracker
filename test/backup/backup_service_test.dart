import "dart:convert";

import "package:drift/drift.dart" hide isNull;
import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:workout_tracker/data/services/backup_service.dart";
import "package:workout_tracker/data/services/shared_preference_service.dart";
import "package:workout_tracker/database/database.dart";

void main() {
  late AppDatabase database;
  late SharedPreferences sharedPreferences;
  late BackupService backupService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      "rest_duration_seconds": 45,
      "workout_index_999": 2,
      "unrelated_setting": "keep",
    });
    sharedPreferences = await SharedPreferences.getInstance();
    database = AppDatabase(NativeDatabase.memory());
    backupService = BackupService(
      database,
      SharedPreferenceService(sharedPreferences),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    "restores a full backup and removes obsolete scoped preferences",
    () async {
      await database
          .into(database.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: const Value(999),
              name: "Existing exercise",
            ),
          );

      final backup = backupService.parseBackupBytes(_validBackupBytes());
      expect(backup.recordCount, 11);
      await backupService.restoreBackup(backup);

      final exercise = await database.select(database.exercises).getSingle();
      expect(exercise.id, 7);
      expect(exercise.name, "Push up");
      final nextExerciseId = await database
          .into(database.exercises)
          .insert(ExercisesCompanion.insert(name: "New exercise"));
      expect(nextExerciseId, 8);
      expect(
        (await database.select(database.workoutSessions).getSingle()).id,
        15,
      );
      expect(
        (await database.select(database.bodyWeightLogs).getSingle()).id,
        5,
      );
      expect(sharedPreferences.getInt("rest_duration_seconds"), 90);
      expect(sharedPreferences.getInt("workout_index_4"), 1);
      expect(sharedPreferences.getInt("workout_index_999"), isNull);
      expect(sharedPreferences.getString("unrelated_setting"), "keep");
    },
  );

  test("rejects malformed backup before changing app data", () async {
    await database
        .into(database.exercises)
        .insert(ExercisesCompanion.insert(name: "Existing exercise"));

    final malformed =
        jsonDecode(utf8.decode(_validBackupBytes())) as Map<String, Object?>;
    malformed["format"] = "other_app_backup";

    expect(
      () => backupService.parseBackupBytes(
        Uint8List.fromList(utf8.encode(jsonEncode(malformed))),
      ),
      throwsA(isA<BackupException>()),
    );
    expect(
      (await database.select(database.exercises).getSingle()).name,
      "Existing exercise",
    );
    expect(sharedPreferences.getInt("rest_duration_seconds"), 45);
  });

  test("rolls back preferences and database when restore fails", () async {
    await database
        .into(database.exercises)
        .insert(ExercisesCompanion.insert(name: "Existing exercise"));
    await database.customStatement("""
      CREATE TRIGGER reject_backup_exercise
      BEFORE INSERT ON exercises
      BEGIN
        SELECT RAISE(FAIL, 'restore test failure');
      END;
    """);
    final backup = backupService.parseBackupBytes(_validBackupBytes());

    await expectLater(
      backupService.restoreBackup(backup),
      throwsA(isA<BackupException>()),
    );

    expect(
      (await database.select(database.exercises).getSingle()).name,
      "Existing exercise",
    );
    expect(sharedPreferences.getInt("rest_duration_seconds"), 45);
    expect(sharedPreferences.getInt("workout_index_999"), 2);
  });

  test("accepts empty tables and an empty preference set", () {
    final backup =
        jsonDecode(utf8.decode(_validBackupBytes())) as Map<String, Object?>;
    final database = backup["database"]! as Map<String, Object?>;
    for (final table in database.keys.toList()) {
      if (table != "streakStats") database[table] = <Object?>[];
    }
    backup["preferences"] = <String, Object?>{};

    final parsed = backupService.parseBackupBytes(
      Uint8List.fromList(utf8.encode(jsonEncode(backup))),
    );
    expect(parsed.recordCount, 1);
    expect(parsed.preferences, isEmpty);
    expect(parsed.exercises, isEmpty);
    expect(parsed.bodyWeightLogs, isEmpty);
  });
}

Uint8List _validBackupBytes() {
  final exportedAt = DateTime.utc(2026, 10, 28).toIso8601String();
  final recordDate = DateTime.utc(2025, 1, 2).toIso8601String();
  final database = <String, Object?>{
    "exercises": [
      {
        "id": 7,
        "name": "Push up",
        "description": null,
        "isBilateral": false,
        "createdAt": recordDate,
        "updatedAt": recordDate,
      },
    ],
    "exerciseSupportedTypes": [
      {"exerciseId": 7, "type": 0},
    ],
    "programs": [
      {"id": 4, "name": "Starter", "isActive": true, "createdAt": recordDate},
    ],
    "workouts": [
      {
        "id": 9,
        "programId": 4,
        "name": "Day one",
        "kind": 0,
        "sets": 2,
        "restDurationSeconds": null,
        "position": 0,
        "createdAt": recordDate,
        "updatedAt": recordDate,
      },
    ],
    "workoutExercises": [
      {
        "id": 11,
        "workoutId": 9,
        "exerciseId": 7,
        "position": 0,
        "type": 0,
        "side": null,
        "targetReps": 10,
        "targetDurationSeconds": null,
      },
    ],
    "workoutSessions": [
      {
        "id": 15,
        "workoutId": 9,
        "programId": 4,
        "startedAt": recordDate,
        "completedAt": null,
      },
    ],
    "sessionCircuits": [
      {
        "id": 20,
        "sessionId": 15,
        "circuitNumber": 1,
        "startedAt": recordDate,
        "completedAt": null,
      },
    ],
    "sessionExerciseLogs": [
      {
        "id": 31,
        "circuitId": 20,
        "exerciseId": 7,
        "position": 0,
        "exerciseType": 0,
        "side": null,
        "targetReps": 10,
        "actualReps": 10,
        "targetDurationSeconds": null,
        "actualDurationSeconds": null,
        "startedAt": recordDate,
        "completedAt": recordDate,
      },
    ],
    "challengeLogs": [
      {
        "id": 44,
        "sessionId": 15,
        "exerciseId": 7,
        "exerciseType": 0,
        "side": null,
        "reps": 10,
        "durationSeconds": null,
        "loggedAt": recordDate,
      },
    ],
    "streakStats": [
      {
        "id": 1,
        "currentStreak": 1,
        "longestStreak": 1,
        "currentStreakStartDate": recordDate,
        "currentStreakEndDate": recordDate,
        "longestStreakStartDate": recordDate,
        "longestStreakEndDate": recordDate,
      },
    ],
    "bodyWeightLogs": [
      {"id": 5, "weightKg": 70.5, "loggedAt": recordDate},
    ],
  };
  final backup = {
    "format": "workout_tracker_backup",
    "backupVersion": 1,
    "databaseSchemaVersion": 6,
    "exportedAt": exportedAt,
    "database": database,
    "preferences": {
      "rest_duration_seconds": {"type": "int", "value": 90},
      "workout_index_4": {"type": "int", "value": 1},
    },
  };
  return Uint8List.fromList(utf8.encode(jsonEncode(backup)));
}
