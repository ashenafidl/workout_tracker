import "package:workout_tracker/database/database.dart";

class SessionHistoryEntry {
  const new({
    required this.session,
    required this.workoutName,
    required this.programName,
    required this.circuitCount,
    required this.exerciseCount,
    required this.duration,
  });

  final WorkoutSession session;
  final String workoutName;
  final String programName;
  final int circuitCount;
  final int exerciseCount;
  final Duration duration;
}

class SessionHistoryGrouping {
  new({
    required this.session,
    required this.workoutName,
    required this.programName,
  });

  final WorkoutSession session;
  final String workoutName;
  final String programName;
  final Set<int> circuitIds = {};
  final Set<int> exerciseIds = {};
}
