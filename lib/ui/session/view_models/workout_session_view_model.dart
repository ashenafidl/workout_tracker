import "dart:async";

import "package:drift/drift.dart";
import "package:flutter/foundation.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/models/session_summary.dart";
import "package:workout_tracker/data/models/workout_session_args.dart";
import "package:workout_tracker/data/services/shared_preference_service.dart";
import "package:workout_tracker/data/services/sound_service.dart";
import "package:workout_tracker/data/services/streak_service.dart";
import "package:workout_tracker/database/database.dart";

enum SessionPhase {
  countdown,
  preparingDuration,
  exercising,
  resting,
  completed,
}

enum SegmentStatus { completed, current, upcoming }

class WorkoutSessionViewModel extends ChangeNotifier {
  new({
    required this.args,
    required this.sharedPreferenceService,
    required this.soundService,
    required this.database,
    required this.streakService,
  });

  final WorkoutSessionArgs args;
  final SharedPreferenceService sharedPreferenceService;
  final SoundService soundService;
  final AppDatabase database;
  final StreakService streakService;

  SessionPhase _phase = SessionPhase.countdown;
  int _countdown = 3;
  int _currentCircuit = 1;
  int _currentStepIndex = 0;
  int _restSecondsRemaining = 0;
  int _durationTargetSeconds = 0;
  int _durationSecondsRemaining = 0;

  int? _sessionId;
  int? _currentCircuitId;
  int? _currentExerciseLogId;
  WorkoutSessionSummary? _summary;

  SessionPhase get phase => _phase;
  int get countdown => _countdown;
  int get currentCircuit => _currentCircuit;
  int get currentStepIndex => _currentStepIndex;
  int get restSecondsRemaining => _restSecondsRemaining;
  bool get isCurrentExerciseDuration =>
      _phase == SessionPhase.exercising &&
      _currentStepIndex < _steps.length &&
      currentExercise.exercise.type == ExerciseType.duration;
  int get durationSecondsRemaining => _durationSecondsRemaining;
  double get durationProgress {
    if (_durationTargetSeconds == 0) {
      return 0;
    }
    return 1 - (_durationSecondsRemaining / _durationTargetSeconds);
  }

  WorkoutSessionSummary? get summary => _summary;

  Timer? _timer;
  Timer? _exerciseTimer;

  int get totalSets => args.workoutWithExercises.workout.sets;
  List<WorkoutExerciseDetail> get exercises =>
      args.workoutWithExercises.exercises;

  /// One unit of work inside a circuit, after expanding bilateral exercises.
  List<SessionStep> get _steps => _stepCache ??= _buildSteps();

  List<SessionStep>? _stepCache;

  List<SessionStep> _buildSteps() {
    return [for (final exercise in exercises) ..._stepsFor(exercise)];
  }

  List<SessionStep> _stepsFor(WorkoutExerciseDetail exercise) {
    final side = exercise.side;
    if (!exercise.isBilateral || side == null) {
      return [SessionStep(exercise: exercise, side: null)];
    }

    return [
      for (final performedSide in side.performedSides)
        SessionStep(exercise: exercise, side: performedSide),
    ];
  }

  /// Number of steps in one circuit, after expanding bilateral exercises.
  int get stepCount => _steps.length;

  SessionStep get currentStep => _steps[_currentStepIndex];
  WorkoutExerciseDetail get currentExercise => currentStep.exercise;

  /// The side to perform right now, already resolved for the current step.
  ExerciseSide? get currentSide => currentStep.side;

  SessionStep? get nextStep {
    if (_currentStepIndex < _steps.length - 1) {
      return _steps[_currentStepIndex + 1];
    }
    if (_currentCircuit < totalSets) return _steps.first;
    return null;
  }

  WorkoutExerciseDetail? get nextExercise => nextStep?.exercise;
  ExerciseSide? get nextSide => nextStep?.side;

  SegmentStatus exerciseStatus(int index) {
    if (index < _currentStepIndex) {
      return SegmentStatus.completed;
    }

    if (index == _currentStepIndex && _phase == SessionPhase.exercising) {
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

  void _startDurationPreparation() {
    _timer?.cancel();
    _phase = SessionPhase.preparingDuration;
    _countdown = 5;
    soundService.playCountdownTick();
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        _countdown--;
        soundService.playCountdownTick();
        notifyListeners();
        return;
      }

      timer.cancel();
      _phase = SessionPhase.exercising;
      notifyListeners();
      unawaited(_beginExercise());
    });
  }

  void _startDurationTimer() {
    _exerciseTimer?.cancel();
    _durationTargetSeconds = currentExercise.targetDurationSeconds ?? 0;
    _durationSecondsRemaining = _durationTargetSeconds;
    if (!isCurrentExerciseDuration || _durationSecondsRemaining == 0) {
      return;
    }

    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_durationSecondsRemaining > 1) {
        _durationSecondsRemaining--;

        if (_durationSecondsRemaining <= 3) {
          soundService.playCountdownTick();
        }

        notifyListeners();
        return;
      }

      _durationSecondsRemaining = 0;
      timer.cancel();
      _exerciseTimer = null;
      notifyListeners();
      unawaited(advance());
    });
  }

  Future<void> _startExercise() async {
    if (currentExercise.exercise.type == ExerciseType.duration) {
      _startDurationPreparation();
      return;
    }

    await _beginExercise();
  }

  Future<void> _beginExercise() async {
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
            position: _currentStepIndex,
            exerciseType: Value(exercise.exercise.type),
            side: Value(currentSide),
            targetReps: Value(exercise.targetReps),
            targetDurationSeconds: Value(exercise.targetDurationSeconds),
            startedAt: now,
          ),
        );
    _startDurationTimer();
    notifyListeners();
  }

  Future<void> advance() async {
    _exerciseTimer?.cancel();
    _exerciseTimer = null;
    if (_phase != SessionPhase.exercising) return;

    final isLastStep = _currentStepIndex == _steps.length - 1;
    final isLastCircuit = _currentCircuit == totalSets;

    if (isLastStep && isLastCircuit) {
      await _completeCurrentExercise();
      await _completeCurrentCircuit();
      await _completeSession();
      _phase = SessionPhase.completed;
      _currentStepIndex++;
      notifyListeners();
      await _loadSessionSummary();
      notifyListeners();
      return;
    }

    if (isLastStep) {
      await _completeCurrentExercise();
      await _completeCurrentCircuit();
      _startRest();
      return;
    }

    await _completeCurrentExercise();
    _currentStepIndex++;
    await _startExercise();
    notifyListeners();
  }

  void _startRest() {
    _timer?.cancel();
    _phase = SessionPhase.resting;
    _restSecondsRemaining = sharedPreferenceService.restDurationSeconds;
    soundService.playRestStart();
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 1) {
        _restSecondsRemaining--;
        if (_restSecondsRemaining <= 3) {
          soundService.playCountdownTick();
        }
        notifyListeners();
        return;
      } else {
        timer.cancel();
        soundService.playRestEnd();
        unawaited(_advanceCircuit());
      }
    });
  }

  Future<void> skipRest() async {
    _timer?.cancel();
    await _advanceCircuit();
  }

  Future<void> _advanceCircuit() async {
    _currentCircuit++;
    _currentStepIndex = 0;
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
        actualReps: Value(currentExercise.targetReps),
        actualDurationSeconds: Value(
          isCurrentExerciseDuration
              ? _durationTargetSeconds - _durationSecondsRemaining
              : currentExercise.targetDurationSeconds,
        ),
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

      await streakService.recordCompletedSession(excludeSessionId: _sessionId);

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

    final runStart = sharedPreferenceService.programRunStartForProgram(
      args.programId,
    );
    final sessions =
        await (database.select(database.workoutSessions)..where((session) {
              final base =
                  session.programId.equals(args.programId) &
                  session.completedAt.isNotNull();
              if (runStart == null) return base;
              return base & session.completedAt.isBiggerOrEqualValue(runStart);
            }))
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
          type: log.exerciseType,
          side: log.side,
          targetReps: log.targetReps,
          actualReps: log.actualReps ?? log.targetReps,
          targetDurationSeconds: log.targetDurationSeconds,
          actualDurationSeconds:
              log.actualDurationSeconds ?? log.targetDurationSeconds,
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
    _exerciseTimer?.cancel();
    super.dispose();
  }
}

/// One unit of work inside a circuit. A bilateral exercise set to
/// [ExerciseSide.both] produces two of these — left, then right — so the two
/// sides are logged and displayed as separate entries.
class SessionStep {
  const new({required this.exercise, required this.side});

  final WorkoutExerciseDetail exercise;
  final ExerciseSide? side;
}
