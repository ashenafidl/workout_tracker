sealed class UnitInputResult {
  const new();
}

class IntegerInputResult extends UnitInputResult {
  const new(this.value);
  final int value;
}

class DurationInputResult extends UnitInputResult {
  const new(this.duration);
  final Duration duration;
}
