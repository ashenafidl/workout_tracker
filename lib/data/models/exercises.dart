import "package:flutter/material.dart";
import "package:workout_tracker/database/database.dart";
import "package:workout_tracker/utils/exercise_label.dart";

class WorkoutExerciseInput {
  const new({
    required this.exerciseId,
    required this.exerciseName,
    required this.type,
    required this.position,
    this.targetReps,
    this.targetDurationSeconds,
  });

  final int exerciseId;
  final String exerciseName;
  final ExerciseType type;
  final int position;
  final int? targetReps;
  final int? targetDurationSeconds;

  String get targetLabel => exerciseTargetLabel(
    type: type,
    targetReps: targetReps,
    targetDurationSeconds: targetDurationSeconds,
  );
}

class WorkoutExerciseDetail {
  const new({
    required this.exercise,
    required this.position,
    this.targetReps,
    this.targetDurationSeconds,
  });

  final Exercise exercise;
  final int position;
  final int? targetReps;
  final int? targetDurationSeconds;

  String get targetLabel => exerciseTargetLabel(
    type: exercise.type,
    targetReps: targetReps,
    targetDurationSeconds: targetDurationSeconds,
  );
}

class WorkoutWithExercises {
  const new({required this.workout, required this.exercises});

  final Workout workout;
  final List<WorkoutExerciseDetail> exercises;
}

enum ExerciseType {
  reps(
    name: "Reps",
    description: "Track repetitions without weight.",
    icon: Icons.repeat,
  ),
  duration(
    name: "Duration",
    description: "Track how long you hold or perform the exercise.",
    icon: Icons.timer_outlined,
  );

  new({required this.name, required this.description, required this.icon});

  final String name;
  final String description;
  final IconData icon;
}
