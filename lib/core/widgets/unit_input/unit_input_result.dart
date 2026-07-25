sealed class UnitInputResult {
  const UnitInputResult();
}

class IntegerInputResult extends UnitInputResult {
  const IntegerInputResult(this.value);
  final int value;
}

class DurationInputResult extends UnitInputResult {
  const DurationInputResult(this.duration);
  final Duration duration;
}
