class StatsSnapshot {
  const new({
    required this.totalWorkouts,
    required this.totalCircuits,
    required this.totalReps,
    required this.totalDuration,
    required this.workoutsByWeekday,
    required this.weekdayWorkouts,
    required this.weekendWorkouts,
  });

  final int totalWorkouts;
  final int totalCircuits;
  final int totalReps;
  final Duration totalDuration;
  final List<int> workoutsByWeekday;
  final int weekdayWorkouts;
  final int weekendWorkouts;
}
