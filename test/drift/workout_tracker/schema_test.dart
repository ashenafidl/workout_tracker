import "package:drift/drift.dart";
import "package:drift/native.dart";
import "package:drift_dev/api/migrations_native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:workout_tracker/database/database.dart";

import "generated/schema.dart";

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test("schemaVersion is 1", () {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 1);
  });

  test("fresh install creates the database at schema version 1", () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final userVersion = await db
        .customSelect("PRAGMA user_version")
        .getSingle();
    expect(userVersion.read<int>("user_version"), 1);

    // Tables match the Drift definitions in database.dart.
    await db.validateDatabaseSchema();

    // onCreate seeds the StreakStats singleton row.
    final stats = await db.select(db.streakStats).getSingle();
    expect(stats.id, 1);
    expect(stats.currentStreak, 0);
  });

  test("fresh install matches the v1 schema snapshot", () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    // Opens a v1 snapshot database at v1 (no migration) and compares it
    // with the schema the app would create.
    await verifier.migrateAndValidate(db, 1);
  });
}
