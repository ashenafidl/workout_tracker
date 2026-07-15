import "package:workout_tracker/database/database.dart";

class ProgramWithWorkoutCount {
  const ProgramWithWorkoutCount({
    required this.program,
    required this.workoutCount,
  });

  final Program program;
  final int workoutCount;
}
