import "package:workout_tracker/data/models/programs.dart";
import "package:workout_tracker/database/database.dart";

class SessionHistoryEntry {
  const new({
    required this.session,
    required this.workoutName,
    required this.programName,
    required this.workoutKind,
    required this.circuitCount,
    required this.exerciseCount,
    required this.duration,
    required this.totalReps,
    required this.totalDurationSeconds,
  });

  final WorkoutSession session;
  final String workoutName;
  final String programName;
  final WorkoutKind workoutKind;
  final int circuitCount;
  final int exerciseCount;
  final Duration duration;
  final int totalReps;
  final int totalDurationSeconds;

  bool get isChallenge => workoutKind == WorkoutKind.challenge;
}

class SessionHistoryGrouping {
  new({
    required this.session,
    required this.workoutName,
    required this.programName,
    required this.workoutKind,
  });

  final WorkoutSession session;
  final String workoutName;
  final String programName;
  final WorkoutKind workoutKind;
  final Set<int> circuitIds = {};
  final Set<int> exerciseIds = {};
  int totalReps = 0;
  int totalDurationSeconds = 0;
}
