import "package:drift/drift.dart";
import "package:workout_tracker/data/models/programs.dart";
import "package:workout_tracker/data/models/session_history.dart";
import "package:workout_tracker/data/services/session_durations.dart";
import "package:workout_tracker/database/database.dart";

class SessionRepo {
  new(this._db);

  final AppDatabase _db;

  /// Completed sessions, newest first, with their durations resolved by
  /// [SessionDurations]. Re-emits whenever any table feeding it changes.
  Stream<List<SessionHistoryEntry>> watchSessionHistory() async* {
    yield await _loadSessionHistory();
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.workoutSessions,
        _db.workouts,
        _db.programs,
        _db.sessionCircuits,
        _db.sessionExerciseLogs,
        _db.challengeLogs,
        _db.challengeScreenVisits,
      ]),
    );
    await for (final _ in updates) {
      yield await _loadSessionHistory();
    }
  }

  Future<List<SessionHistoryEntry>> _loadSessionHistory() async {
    final sessionRows =
        await (_db.select(_db.workoutSessions).join([
                innerJoin(
                  _db.workouts,
                  _db.workouts.id.equalsExp(_db.workoutSessions.workoutId),
                ),
                innerJoin(
                  _db.programs,
                  _db.programs.id.equalsExp(_db.workoutSessions.programId),
                ),
              ])
              ..where(_db.workoutSessions.completedAt.isNotNull())
              ..orderBy([
                OrderingTerm(
                  expression: _db.workoutSessions.completedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    if (sessionRows.isEmpty) return const [];

    final sessionIds = [
      for (final row in sessionRows) row.readTable(_db.workoutSessions).id,
    ];

    final circuits = await (_db.select(
      _db.sessionCircuits,
    )..where((circuit) => circuit.sessionId.isIn(sessionIds))).get();
    final circuitsBySession = _groupBy(circuits, (c) => c.sessionId);
    final sessionByCircuit = {
      for (final circuit in circuits) circuit.id: circuit.sessionId,
    };

    final exerciseLogs = await (_db.select(
      _db.sessionExerciseLogs,
    )..where((log) => log.circuitId.isIn(sessionByCircuit.keys))).get();
    final exerciseIdsBySession = <int, Set<int>>{};
    for (final log in exerciseLogs) {
      exerciseIdsBySession
          .putIfAbsent(sessionByCircuit[log.circuitId]!, () => {})
          .add(log.exerciseId);
    }

    final challengeLogs = await (_db.select(
      _db.challengeLogs,
    )..where((log) => log.sessionId.isIn(sessionIds))).get();
    final challengeLogsBySession = _groupBy(challengeLogs, (l) => l.sessionId);

    final visits = await (_db.select(
      _db.challengeScreenVisits,
    )..where((visit) => visit.sessionId.isIn(sessionIds))).get();
    final visitsBySession = _groupBy(visits, (v) => v.sessionId);

    return [
      for (final row in sessionRows)
        _toEntry(
          session: row.readTable(_db.workoutSessions),
          workout: row.readTable(_db.workouts),
          program: row.readTable(_db.programs),
          circuitsBySession: circuitsBySession,
          exerciseIdsBySession: exerciseIdsBySession,
          challengeLogsBySession: challengeLogsBySession,
          visitsBySession: visitsBySession,
        ),
    ];
  }

  SessionHistoryEntry _toEntry({
    required WorkoutSession session,
    required Workout workout,
    required Program program,
    required Map<int, List<SessionCircuit>> circuitsBySession,
    required Map<int, Set<int>> exerciseIdsBySession,
    required Map<int, List<ChallengeLog>> challengeLogsBySession,
    required Map<int, List<ChallengeScreenVisit>> visitsBySession,
  }) {
    final circuits = circuitsBySession[session.id] ?? const [];
    final challengeLogs = challengeLogsBySession[session.id] ?? const [];
    final isChallenge = workout.kind == WorkoutKind.challenge;

    return SessionHistoryEntry(
      session: session,
      workoutName: workout.name,
      programName: program.name,
      workoutKind: workout.kind,
      circuitCount: circuits.length,
      exerciseCount: exerciseIdsBySession[session.id]?.length ?? 0,
      durations: isChallenge
          ? SessionDurations.forChallengeSession(
              logs: challengeLogs,
              visits: visitsBySession[session.id] ?? const [],
            )
          : SessionDurations.forCircuitSession(
              startedAt: session.startedAt,
              completedAt: session.completedAt!,
              circuits: circuits,
            ),
      totalReps: challengeLogs.fold(0, (sum, log) => sum + (log.reps ?? 0)),
      totalDurationSeconds: challengeLogs.fold(
        0,
        (sum, log) => sum + (log.durationSeconds ?? 0),
      ),
    );
  }
}

Map<int, List<T>> _groupBy<T>(List<T> rows, int Function(T) key) {
  final grouped = <int, List<T>>{};
  for (final row in rows) {
    grouped.putIfAbsent(key(row), () => []).add(row);
  }
  return grouped;
}
