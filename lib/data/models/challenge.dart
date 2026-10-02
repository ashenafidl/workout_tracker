import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/database/database.dart";

class ChallengeExerciseProgress {
  const new({
    required this.workoutExerciseId,
    required this.exercise,
    required this.side,
    required this.targetReps,
    required this.targetDurationSeconds,
    required this.accumulatedReps,
    required this.accumulatedDurationSeconds,
  });

  final int workoutExerciseId;
  final Exercise exercise;
  final ExerciseSide? side;
  final int? targetReps;
  final int? targetDurationSeconds;
  final int accumulatedReps;
  final int accumulatedDurationSeconds;

  bool get isComplete {
    if (targetReps != null) return accumulatedReps >= targetReps!;
    if (targetDurationSeconds != null) {
      return accumulatedDurationSeconds >= targetDurationSeconds!;
    }
    return false;
  }

  double get progressFraction {
    if (targetReps != null && targetReps! > 0) {
      return (accumulatedReps / targetReps!).clamp(0.0, 1.0);
    }
    if (targetDurationSeconds != null && targetDurationSeconds! > 0) {
      return (accumulatedDurationSeconds / targetDurationSeconds!).clamp(
        0.0,
        1.0,
      );
    }
    return 0;
  }
}

class ChallengeScreenArgs {
  final WorkoutWithExercises workoutWithExercises;
  final int programId;

  const new({required this.workoutWithExercises, required this.programId});
}
