import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/utils/exercise_label.dart";

class WorkoutSessionSummary {
  const new({
    required this.workoutName,
    required this.startedAt,
    required this.completedAt,
    required this.circuits,
  });

  final String workoutName;
  final DateTime startedAt;
  final DateTime completedAt;
  final List<CircuitSummary> circuits;

  Duration get totalDuration => completedAt.difference(startedAt);
  Duration get totalRestDuration => circuits.fold(
    Duration.zero,
    (sum, circuit) => sum + circuit.restDuration,
  );
}

class CircuitSummary {
  const new({
    required this.circuitNumber,
    required this.startedAt,
    required this.completedAt,
    required this.restDuration,
    required this.exercises,
  });

  final int circuitNumber;
  final DateTime startedAt;
  final DateTime completedAt;
  final Duration restDuration;
  final List<ExerciseSummary> exercises;

  Duration get duration => completedAt.difference(startedAt);
}

class ExerciseSummary {
  const new({
    required this.name,
    required this.type,
    required this.startedAt,
    required this.completedAt,
    this.side,
    this.targetReps,
    this.actualReps,
    this.targetDurationSeconds,
    this.actualDurationSeconds,
  });

  final String name;
  final ExerciseType type;
  final ExerciseSide? side;
  final int? targetReps;
  final int? actualReps;
  final int? targetDurationSeconds;
  final int? actualDurationSeconds;
  final DateTime startedAt;
  final DateTime completedAt;

  String get targetLabel => exerciseTargetLabel(
    type: type,
    targetReps: targetReps,
    targetDurationSeconds: targetDurationSeconds,
  );

  String get actualLabel => exerciseTargetLabel(
    type: type,
    targetReps: actualReps,
    targetDurationSeconds: actualDurationSeconds,
  );

  Duration get duration => completedAt.difference(startedAt);
}
