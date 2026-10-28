import "package:shared_preferences/shared_preferences.dart";

class SharedPreferenceService {
  new(this._prefs);

  final SharedPreferences _prefs;

  static const _keyRestDuration = "rest_duration_seconds";
  static const _keyWorkoutIndex = "workout_index_";
  static const _keyProgramRunStart = "program_run_start_";

  Map<String, int> exportBackupPreferences() {
    final result = <String, int>{};
    for (final key in _prefs.getKeys()) {
      if (!_isBackupPreferenceKey(key)) continue;
      _validatePreferenceKey(key);
      final value = _prefs.get(key);
      if (value is! int) {
        throw StateError("Preference '$key' does not contain an integer.");
      }
      result[key] = value;
    }
    return result;
  }

  bool isBackupPreferenceKey(String key) => _isBackupPreferenceKey(key);

  void validateBackupPreferenceKey(String key) {
    if (!_isBackupPreferenceKey(key)) {
      throw ArgumentError.value(
        key,
        "key",
        "Preference is outside the backup scope.",
      );
    }
    _validatePreferenceKey(key);
  }

  Future<void> replaceBackupPreferences(Map<String, int> preferences) async {
    for (final entry in preferences.entries) {
      if (!_isBackupPreferenceKey(entry.key)) {
        throw ArgumentError.value(
          entry.key,
          "preferences",
          "Preference is outside the backup scope.",
        );
      }
      _validatePreferenceKey(entry.key);
    }

    final keysToRemove = _prefs
        .getKeys()
        .where(
          (key) => _isBackupPreferenceKey(key) && !preferences.containsKey(key),
        )
        .toList();
    for (final key in keysToRemove) {
      if (!await _prefs.remove(key)) {
        throw StateError("Could not remove preference '$key'.");
      }
    }
    for (final entry in preferences.entries) {
      if (!await _prefs.setInt(entry.key, entry.value)) {
        throw StateError("Could not save preference '${entry.key}'.");
      }
    }
  }

  bool _isBackupPreferenceKey(String key) =>
      key == _keyRestDuration ||
      key.startsWith(_keyWorkoutIndex) ||
      key.startsWith(_keyProgramRunStart);

  void _validatePreferenceKey(String key) {
    if (key == _keyRestDuration) return;
    final suffix = key.startsWith(_keyWorkoutIndex)
        ? key.substring(_keyWorkoutIndex.length)
        : key.substring(_keyProgramRunStart.length);
    final programId = int.tryParse(suffix);
    if (programId == null || programId < 1 || programId.toString() != suffix) {
      throw StateError("Preference key '$key' has an invalid program ID.");
    }
  }

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
