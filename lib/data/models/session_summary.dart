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
    required this.targetReps,
    required this.actualReps,
    required this.startedAt,
    required this.completedAt,
  });

  final String name;
  final int targetReps;
  final int actualReps;
  final DateTime startedAt;
  final DateTime completedAt;

  Duration get duration => completedAt.difference(startedAt);
}
