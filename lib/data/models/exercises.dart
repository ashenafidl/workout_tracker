import "package:workout_tracker/database/database.dart";

class WorkoutExerciseInput {
  const WorkoutExerciseInput({
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
  const WorkoutExerciseDetail({
    required this.exercise,
    required this.reps,
    required this.position,
  });

  final Exercise exercise;
  final int reps;
  final int position;
}

class WorkoutWithExercises {
  const WorkoutWithExercises({required this.workout, required this.exercises});

  final Workout workout;
  final List<WorkoutExerciseDetail> exercises;
}
