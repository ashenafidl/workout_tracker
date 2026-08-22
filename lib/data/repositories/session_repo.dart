import "package:drift/drift.dart";
import "package:workout_tracker/data/models/session_history.dart";
import "package:workout_tracker/database/database.dart";

class SessionRepository {
  new(this._db);

  final AppDatabase _db;

  Stream<List<SessionHistoryEntry>> watchSessionHistory() {
    final query =
        _db.select(_db.workoutSessions).join([
            innerJoin(
              _db.workouts,
              _db.workouts.id.equalsExp(_db.workoutSessions.workoutId),
            ),
            innerJoin(
              _db.programs,
              _db.programs.id.equalsExp(_db.workoutSessions.programId),
            ),
            leftOuterJoin(
              _db.sessionCircuits,
              _db.sessionCircuits.sessionId.equalsExp(_db.workoutSessions.id),
            ),
            leftOuterJoin(
              _db.sessionExerciseLogs,
              _db.sessionExerciseLogs.circuitId.equalsExp(
                _db.sessionCircuits.id,
              ),
            ),
          ])
          ..where(_db.workoutSessions.completedAt.isNotNull())
          ..orderBy([
            OrderingTerm(
              expression: _db.workoutSessions.completedAt,
              mode: OrderingMode.desc,
            ),
          ]);

    return query.watch().map((rows) {
      final grouped = <int, SessionHistoryGrouping>{};
      for (final row in rows) {
        final session = row.readTable(_db.workoutSessions);
        final workout = row.readTable(_db.workouts);
        final program = row.readTable(_db.programs);
        final grouping = grouped.putIfAbsent(
          session.id,
          () => SessionHistoryGrouping(
            session: session,
            workoutName: workout.name,
            programName: program.name,
          ),
        );
        final circuit = row.readTableOrNull(_db.sessionCircuits);
        final log = row.readTableOrNull(_db.sessionExerciseLogs);
        if (circuit != null) {
          grouping.circuitIds.add(circuit.id);
        }
        if (log != null) {
          grouping.exerciseIds.add(log.exerciseId);
        }
      }

      return grouped.values.map((group) {
        final completedAt = group.session.completedAt!;
        return SessionHistoryEntry(
          session: group.session,
          workoutName: group.workoutName,
          programName: group.programName,
          circuitCount: group.circuitIds.length,
          exerciseCount: group.exerciseIds.length,
          duration: completedAt.difference(group.session.startedAt),
        );
      }).toList();
    });
  }
}
