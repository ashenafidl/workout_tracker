/// Defines how a unit input behaves: what value it holds, how to display it,
/// and how to increment/decrement it.
sealed class UnitInputConfig {
  const UnitInputConfig();
}

class IntegerInputConfig extends UnitInputConfig {
  const IntegerInputConfig({
    required this.initialValue,
    this.label,
    this.min = 1,
    this.step = 1,
  });

  final int initialValue;
  final String? label;
  final int min;
  final int step;
}

class DurationInputConfig extends UnitInputConfig {
  const DurationInputConfig({
    required this.initialDuration,
    this.stepSeconds = 15,
  });

  final Duration initialDuration;
  final int stepSeconds;
}
