import "package:workout_tracker/data/models/exercises.dart";

sealed class UnitInputResult {
  const new();

  ExerciseType get type;
}

class IntegerInputResult extends UnitInputResult {
  const new(this.value, {required this.type});

  final int value;

  @override
  final ExerciseType type;
}

class DurationInputResult extends UnitInputResult {
  const new(this.duration, {required this.type});

  final Duration duration;

  @override
  final ExerciseType type;
}
