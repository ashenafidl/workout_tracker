import "package:workout_tracker/database/database.dart";

class WorkoutExerciseInput {
  const new({
    required this.exerciseId,
    required this.exerciseName,
    required this.reps,
    required this.position,
  });

  final int exerciseId;
  final String exerciseName;
  final int reps;
  final int position;
}

class WorkoutExerciseDetail {
  const new({
    required this.exercise,
    required this.reps,
    required this.position,
  });

  final Exercise exercise;
  final int reps;
  final int position;
}

class WorkoutWithExercises {
  const new({required this.workout, required this.exercises});

  final Workout workout;
  final List<WorkoutExerciseDetail> exercises;
}
