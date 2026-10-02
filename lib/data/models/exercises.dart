import "package:flutter/material.dart";
import "package:workout_tracker/database/database.dart";
import "package:workout_tracker/utils/exercise_label.dart";

class WorkoutExerciseInput {
  const new({
    required this.exerciseId,
    required this.exerciseName,
    required this.type,
    required this.position,
    required this.isBilateral,
    this.side,
    int? targetReps,
    int? targetDurationSeconds,
  }) : targetReps = type == ExerciseType.reps ? targetReps : null,
       targetDurationSeconds = type == ExerciseType.reps
           ? null
           : targetDurationSeconds;

  final int exerciseId;
  final String exerciseName;
  final ExerciseType type;
  final int position;
  final bool isBilateral;
  final ExerciseSide? side;
  final int? targetReps;
  final int? targetDurationSeconds;

  WorkoutExerciseInput copyWith({
    int? position,
    ExerciseSide? side,
    int? targetReps,
    int? targetDurationSeconds,
  }) {
    return WorkoutExerciseInput(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      type: type,
      position: position ?? this.position,
      isBilateral: isBilateral,
      side: side ?? this.side,
      targetReps: targetReps ?? this.targetReps,
      targetDurationSeconds:
          targetDurationSeconds ?? this.targetDurationSeconds,
    );
  }

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
    this.isBilateral = false,
    this.side,
    this.targetReps,
    this.targetDurationSeconds,
  });

  final Exercise exercise;
  final int position;
  final bool isBilateral;
  final ExerciseSide? side;
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

enum ExerciseSide {
  left(
    name: "Left",
    shortLabel: "L",
    description: "Only the left side.",
    icon: Icons.arrow_back,
  ),
  right(
    name: "Right",
    shortLabel: "R",
    description: "Only the right side.",
    icon: Icons.arrow_forward,
  ),
  both(
    name: "Both",
    shortLabel: "L/R",
    description: "Left then right, once each per circuit.",
    icon: Icons.swap_horiz,
  );

  new({
    required this.name,
    required this.shortLabel,
    required this.description,
    required this.icon,
  });

  final String name;
  final String shortLabel;
  final String description;
  final IconData icon;

  /// The sides actually performed for this side choice, in order. Always at
  /// least one entry, so a unilateral exercise ([none]) still contributes a
  /// single step to a session; only [both] expands into two.
  List<ExerciseSide> get performedSides => switch (this) {
    ExerciseSide.both => const [ExerciseSide.left, ExerciseSide.right],
    _ => [this],
  };
}
