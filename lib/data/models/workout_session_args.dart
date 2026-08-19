import "package:workout_tracker/data/models/exercises.dart";

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
