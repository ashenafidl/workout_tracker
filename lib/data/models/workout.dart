import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/models/programs.dart";

class WorkoutSessionArgs {
  const new({
    required this.workoutWithExercises,
    required this.programId,
    required this.workoutIndex,
    required this.totalWorkoutsInProgram,
  });

  final WorkoutWithExercises workoutWithExercises;
  final int programId;
  final int workoutIndex;
  final int totalWorkoutsInProgram;
}

class WorkoutScreenArgs {
  const new({
    required this.programId,
    this.workoutId,
    this.initialName,
    this.initialSets,
    this.initialKind,
    this.initialRestDurationSeconds,
    this.initialExercises,
  });

  final int programId;
  final int? workoutId;
  final String? initialName;
  final int? initialSets;
  final WorkoutKind? initialKind;
  final int? initialRestDurationSeconds;
  final List<WorkoutExerciseDetail>? initialExercises;
}
