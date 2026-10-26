class StatsSnapshot {
  const new({
    required this.totalWorkouts,
    required this.totalDuration,
    required this.workoutsByWeekday,
    required this.weekdayWorkouts,
    required this.weekendWorkouts,
  });

  final int totalWorkouts;
  final Duration totalDuration;
  final List<int> workoutsByWeekday;
  final int weekdayWorkouts;
  final int weekendWorkouts;
}
