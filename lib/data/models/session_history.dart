import "package:workout_tracker/data/models/programs.dart";
import "package:workout_tracker/data/services/session_durations.dart";
import "package:workout_tracker/database/database.dart";

class SessionHistoryEntry {
  const new({
    required this.session,
    required this.workoutName,
    required this.programName,
    required this.workoutKind,
    required this.circuitCount,
    required this.exerciseCount,
    required this.durations,
    required this.totalReps,
    required this.totalDurationSeconds,
  });

  final WorkoutSession session;
  final String workoutName;
  final String programName;
  final WorkoutKind workoutKind;
  final int circuitCount;
  final int exerciseCount;
  final SessionDurations durations;
  final int totalReps;
  final int totalDurationSeconds;

  /// Workout plus rest time; see [SessionDurations].
  Duration get duration => durations.total;

  bool get isChallenge => workoutKind == WorkoutKind.challenge;
}
