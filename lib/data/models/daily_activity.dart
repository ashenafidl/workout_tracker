class DailyActivity {
  const new({
    required this.date,
    required this.workoutDuration,
    required this.restDuration,
  });

  final DateTime date;
  final Duration workoutDuration;
  final Duration restDuration;
}
