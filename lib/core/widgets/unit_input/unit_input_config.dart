/// Defines how a unit input behaves: what value it holds, how to display it,
/// and how to increment/decrement it.
sealed class UnitInputConfig {
  const new();
}

class IntegerInputConfig extends UnitInputConfig {
  const new({
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

class DoubleInputConfig extends UnitInputConfig {
  const new({
    required this.initialValue,
    this.label,
    this.min = 0,
    this.step = 0.1,
    this.decimalPlaces = 1,
  }) : assert(step > 0),
       assert(decimalPlaces >= 0 && decimalPlaces <= 20);

  final double initialValue;
  final String? label;
  final double min;
  final double step;
  final int decimalPlaces;
}

class DurationInputConfig extends UnitInputConfig {
  const new({required this.initialDuration, this.stepSeconds = 15});

  final Duration initialDuration;
  final int stepSeconds;
}
