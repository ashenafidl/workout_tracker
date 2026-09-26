import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/utils/format_time.dart";

String exerciseTargetLabel({
  required ExerciseType type,
  int? targetReps,
  int? targetDurationSeconds,
  double? targetWeightKg,
  double? targetDistanceMeters,
}) {
  return switch (type) {
    ExerciseType.reps => "${targetReps ?? 0} reps",
    ExerciseType.duration => formatDuration(
      Duration(seconds: targetDurationSeconds ?? 0),
    ),
  };
}
