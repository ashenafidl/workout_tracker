import "dart:async";

import "package:drift/drift.dart";
import "package:flutter/foundation.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/models/session_summary.dart";
import "package:workout_tracker/data/models/workout_session_args.dart";
import "package:workout_tracker/data/services/shared_preference_service.dart";
import "package:workout_tracker/database/database.dart";

enum SessionPhase { countdown, exercising, resting, completed }

enum SegmentStatus { completed, current, upcoming }

class WorkoutSessionViewModel extends ChangeNotifier {
  new({
    required this.args,
    required this.sharedPreferenceService,
    required this.database,
  });

  final WorkoutSessionArgs args;
  final SharedPreferenceService sharedPreferenceService;
  final AppDatabase database;

  SessionPhase _phase = SessionPhase.countdown;
  int _countdown = 3;
  int _currentCircuit = 1;
  int _currentExerciseIndex = 0;
  int _restSecondsRemaining = 0;

  int? _sessionId;
  int? _currentCircuitId;
  int? _currentExerciseLogId;
  WorkoutSessionSummary? _summary;

  SessionPhase get phase => _phase;
  int get countdown => _countdown;
  int get currentCircuit => _currentCircuit;
  int get restSecondsRemaining => _restSecondsRemaining;
  WorkoutSessionSummary? get summary => _summary;

  Timer? _timer;

  int get totalSets => args.workoutWithExercises.workout.sets;
  List<WorkoutExerciseDetail> get exercises =>
      args.workoutWithExercises.exercises;
  WorkoutExerciseDetail get currentExercise => exercises[_currentExerciseIndex];
  WorkoutExerciseDetail? get nextExercise {
    if (_currentExerciseIndex < exercises.length - 1) {
      return exercises[_currentExerciseIndex + 1];
    }
    if (_currentCircuit < totalSets) return exercises[0];
    return null;
  }

  SegmentStatus exerciseStatus(int index) {
    if (index < _currentExerciseIndex) {
      return SegmentStatus.completed;
    }

    if (index == _currentExerciseIndex && _phase == SessionPhase.exercising) {
      return SegmentStatus.current;
    }

    return SegmentStatus.upcoming;
  }

  void startCountDown() {
    _phase = SessionPhase.countdown;
    _countdown = 3;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        _countdown--;
        notifyListeners();
        return;
      }

      timer.cancel();
      unawaited(_onCountdownComplete());
    });
  }

  Future<void> _onCountdownComplete() async {
    await _startSession();
    _phase = SessionPhase.exercising;
    notifyListeners();
    await _startExercise();
  }

  Future<void> _startSession() async {
    final now = DateTime.now();
    _sessionId = await database
        .into(database.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            workoutId: args.workoutWithExercises.workout.id,
            programId: args.programId,
            startedAt: now,
          ),
        );
    await _createCircuit(startedAt: now);
  }

  Future<void> _createCircuit({required DateTime startedAt}) async {
    if (_sessionId == null) {
      throw StateError("Session must be created before a circuit can start.");
    }

    _currentCircuitId = await database
        .into(database.sessionCircuits)
        .insert(
          SessionCircuitsCompanion.insert(
            sessionId: _sessionId!,
            circuitNumber: _currentCircuit,
            startedAt: startedAt,
          ),
        );
  }

  Future<void> _startExercise() async {
    if (_currentCircuitId == null) {
      throw StateError("Circuit must be created before an exercise can start.");
    }

    final now = DateTime.now();
    final exercise = currentExercise;
    _currentExerciseLogId = await database
        .into(database.sessionExerciseLogs)
        .insert(
          SessionExerciseLogsCompanion.insert(
            circuitId: _currentCircuitId!,
            exerciseId: exercise.exercise.id,
            position: _currentExerciseIndex,
            targetReps: exercise.reps,
            startedAt: now,
          ),
        );
  }

  Future<void> advance() async {
    if (_phase != SessionPhase.exercising) return;

    final isLastExercise = _currentExerciseIndex == exercises.length - 1;
    final isLastCircuit = _currentCircuit == totalSets;

    if (isLastExercise && isLastCircuit) {
      await _completeCurrentExercise();
      await _completeCurrentCircuit();
      await _completeSession();
      _phase = SessionPhase.completed;
      _currentExerciseIndex++;
      notifyListeners();
      await _loadSessionSummary();
      notifyListeners();
      return;
    }

    if (isLastExercise) {
      await _completeCurrentExercise();
      await _completeCurrentCircuit();
      _startRest();
      return;
    }

    await _completeCurrentExercise();
    _currentExerciseIndex++;
    await _startExercise();
    notifyListeners();
  }

  void _startRest() {
    _timer?.cancel();
    _phase = SessionPhase.resting;
    _restSecondsRemaining = sharedPreferenceService.restDurationSeconds;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 1) {
        _restSecondsRemaining--;
        notifyListeners();
        return;
      }

      timer.cancel();
      unawaited(_advanceCircuit());
    });
  }

  Future<void> skipRest() async {
    _timer?.cancel();
    await _advanceCircuit();
  }

  Future<void> _advanceCircuit() async {
    _currentCircuit++;
    _currentExerciseIndex = 0;
    _phase = SessionPhase.exercising;
    await _createCircuit(startedAt: DateTime.now());
    notifyListeners();
    await _startExercise();
  }

  Future<void> _completeCurrentExercise() async {
    if (_currentExerciseLogId == null) return;

    final now = DateTime.now();
    await (database.update(
      database.sessionExerciseLogs,
    )..where((log) => log.id.equals(_currentExerciseLogId!))).write(
      SessionExerciseLogsCompanion(
        completedAt: Value(now),
        actualReps: Value(currentExercise.reps),
      ),
    );

    _currentExerciseLogId = null;
  }

  Future<void> _completeCurrentCircuit() async {
    if (_currentCircuitId == null) return;

    final now = DateTime.now();
    await (database.update(database.sessionCircuits)
          ..where((circuit) => circuit.id.equals(_currentCircuitId!)))
        .write(SessionCircuitsCompanion(completedAt: Value(now)));
  }

  Future<void> _completeSession() async {
    if (_sessionId == null) return;

    final now = DateTime.now();
    await database.transaction(() async {
      await (database.update(database.workoutSessions)
            ..where((session) => session.id.equals(_sessionId!)))
          .write(WorkoutSessionsCompanion(completedAt: Value(now)));

      await _deactivateProgramIfFinished();
    });
  }

  /// Completing the last workout finishes the program, so it loses its
  /// active flag and stops showing up as today's workout on the home screen.
  Future<void> _deactivateProgramIfFinished() async {
    final workouts = await (database.select(
      database.workouts,
    )..where((w) => w.programId.equals(args.programId))).get();

    if (workouts.isEmpty) return;

    final sessions =
        await (database.select(database.workoutSessions)..where(
              (session) =>
                  session.programId.equals(args.programId) &
                  session.completedAt.isNotNull(),
            ))
            .get();
    final completedIds = sessions.map((session) => session.workoutId).toSet();

    final allCompleted = workouts.every(
      (workout) => completedIds.contains(workout.id),
    );
    if (allCompleted) {
      await (database.update(database.programs)
            ..where((program) => program.id.equals(args.programId)))
          .write(const ProgramsCompanion(isActive: Value(false)));
    }
  }

  Future<void> _loadSessionSummary() async {
    if (_sessionId == null) return;

    final session = await (database.select(
      database.workoutSessions,
    )..where((session) => session.id.equals(_sessionId!))).getSingle();
    final circuits =
        await (database.select(database.sessionCircuits)
              ..where((circuit) => circuit.sessionId.equals(_sessionId!))
              ..orderBy([(c) => OrderingTerm(expression: c.circuitNumber)]))
            .get();

    final circuitSummaries = <CircuitSummary>[];
    for (var index = 0; index < circuits.length; index++) {
      final circuit = circuits[index];
      final logs =
          await (database.select(database.sessionExerciseLogs).join([
                  leftOuterJoin(
                    database.exercises,
                    database.exercises.id.equalsExp(
                      database.sessionExerciseLogs.exerciseId,
                    ),
                  ),
                ])
                ..where(
                  database.sessionExerciseLogs.circuitId.equals(circuit.id),
                )
                ..orderBy([
                  OrderingTerm(
                    expression: database.sessionExerciseLogs.position,
                  ),
                ]))
              .get();

      final exercises = logs.map((row) {
        final log = row.readTable(database.sessionExerciseLogs);
        final exercise = row.readTable(database.exercises);

        return ExerciseSummary(
          name: exercise.name,
          targetReps: log.targetReps,
          actualReps: log.actualReps ?? log.targetReps,
          startedAt: log.startedAt,
          completedAt: log.completedAt ?? log.startedAt,
        );
      }).toList();

      final restDuration =
          index < circuits.length - 1 && circuit.completedAt != null
          ? circuits[index + 1].startedAt.difference(circuit.completedAt!)
          : Duration.zero;

      circuitSummaries.add(
        CircuitSummary(
          circuitNumber: circuit.circuitNumber,
          startedAt: circuit.startedAt,
          completedAt: circuit.completedAt ?? circuit.startedAt,
          restDuration: restDuration,
          exercises: exercises,
        ),
      );
    }

    _summary = WorkoutSessionSummary(
      workoutName: args.workoutWithExercises.workout.name,
      startedAt: session.startedAt,
      completedAt: session.completedAt ?? session.startedAt,
      circuits: circuitSummaries,
    );
  }

  Future<void> finishWorkout() async {
    final nextIndex = (args.workoutIndex + 1) % args.totalWorkoutsInProgram;
    await sharedPreferenceService.setWorkoutIndexForProgram(
      args.programId,
      nextIndex,
    );
    _phase = SessionPhase.completed;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
