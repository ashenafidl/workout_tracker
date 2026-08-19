import "package:shared_preferences/shared_preferences.dart";

class SharedPreferenceService {
  new(this._prefs);

  final SharedPreferences _prefs;

  static const _keyRestDuration = "rest_duration_seconds";
  static const _keyWorkoutIndex = "workout_index_";

  // Rest duration
  int get restDurationSeconds => _prefs.getInt(_keyRestDuration) ?? 120;
  Future<void> setRestDurationSeconds(int seconds) =>
      _prefs.setInt(_keyRestDuration, seconds);

  // Workout Index for active program
  int workoutIndexForProgram(int programId) =>
      _prefs.getInt("$_keyWorkoutIndex$programId") ?? 0;
  Future<void> setWorkoutIndexForProgram(int programId, int index) =>
      _prefs.setInt("$_keyWorkoutIndex$programId", index);
}
