import "package:shared_preferences/shared_preferences.dart";

class SharedPreferenceService {
  new(this._prefs);

  final SharedPreferences _prefs;

  static const _keyRestDuration = "rest_duration_seconds";
  static const _keyWorkoutIndex = "workout_index_";
  static const _keyProgramRunStart = "program_run_start_";

  // Rest duration
  int get restDurationSeconds => _prefs.getInt(_keyRestDuration) ?? 120;
  Future<void> setRestDurationSeconds(int seconds) =>
      _prefs.setInt(_keyRestDuration, seconds);

  // Workout Index for active program
  int workoutIndexForProgram(int programId) =>
      _prefs.getInt("$_keyWorkoutIndex$programId") ?? 0;
  Future<void> setWorkoutIndexForProgram(int programId, int index) =>
      _prefs.setInt("$_keyWorkoutIndex$programId", index);

  // Start of the current run of a program. Sessions completed before this
  // timestamp belong to a previous run and no longer count towards progress.
  DateTime? programRunStartForProgram(int programId) {
    final millis = _prefs.getInt("$_keyProgramRunStart$programId");
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setProgramRunStartForProgram(int programId, DateTime value) =>
      _prefs.setInt(
        "$_keyProgramRunStart$programId",
        value.millisecondsSinceEpoch,
      );
}
