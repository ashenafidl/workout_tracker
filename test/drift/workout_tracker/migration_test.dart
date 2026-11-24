import "package:drift/drift.dart";
import "package:drift_dev/api/migrations_native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:workout_tracker/database/database.dart";

import "generated/schema.dart";
import "generated/schema_v1.dart" as v1;
import "generated/schema_v2.dart" as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group("simple database migrations", () {
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group("from $fromVersion", () {
        for (final toVersion in versions.skip(i + 1)) {
          test("to $toVersion", () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test("v1 to v2 keeps challenge history and adds empty visits", () async {
    const timestamp = 1764000000;

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.exercises, [
          const v1.ExercisesData(
            id: 1,
            name: "Push up",
            isBilateral: 0,
            createdAt: timestamp,
            updatedAt: timestamp,
          ),
        ]);
        batch.insertAll(oldDb.programs, [
          const v1.ProgramsData(
            id: 1,
            name: "Program",
            isActive: 1,
            createdAt: timestamp,
          ),
        ]);
        batch.insertAll(oldDb.workouts, [
          const v1.WorkoutsData(
            id: 1,
            programId: 1,
            name: "Challenge",
            kind: 1,
            sets: 1,
            position: 0,
            createdAt: timestamp,
            updatedAt: timestamp,
          ),
        ]);
        batch.insertAll(oldDb.workoutSessions, [
          const v1.WorkoutSessionsData(
            id: 1,
            workoutId: 1,
            programId: 1,
            startedAt: timestamp,
            completedAt: timestamp + 600,
          ),
        ]);
        batch.insertAll(oldDb.challengeLogs, [
          const v1.ChallengeLogsData(
            id: 1,
            sessionId: 1,
            exerciseId: 1,
            exerciseType: 0,
            reps: 10,
            loggedAt: timestamp + 60,
          ),
        ]);
        batch.insertAll(oldDb.streakStats, [
          const v1.StreakStatsData(id: 1, currentStreak: 1, longestStreak: 1),
        ]);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.challengeLogs).get(), [
          const v2.ChallengeLogsData(
            id: 1,
            sessionId: 1,
            exerciseId: 1,
            exerciseType: 0,
            reps: 10,
            loggedAt: timestamp + 60,
          ),
        ]);
        expect(await newDb.select(newDb.workoutSessions).get(), hasLength(1));
        expect(await newDb.select(newDb.streakStats).get(), hasLength(1));
        expect(await newDb.select(newDb.challengeScreenVisits).get(), isEmpty);
      },
    );
  });
}
