import "package:workout_tracker/data/models/exercises.dart";

sealed class UnitInputResult {
  const new();
}

class IntegerInputResult extends UnitInputResult {
  const new(this.value, {required this.type});

  final int value;

  final ExerciseType type;
}

class DoubleInputResult extends UnitInputResult {
  const new(this.value);

  final double value;
}

class DurationInputResult extends UnitInputResult {
  const new(this.duration, {required this.type});

  final Duration duration;

  final ExerciseType type;
}
