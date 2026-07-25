import "package:shared_preferences/shared_preferences.dart";

class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const _keyRestDuration = "rest_duration_seconds";
  static const _keyActiveProgramId = "active_program_id";

  // Rest duration
  int get restDurationSeconds => _prefs.getInt(_keyRestDuration) ?? 120;
  Future<void> setRestDurationSeconds(int seconds) =>
      _prefs.setInt(_keyRestDuration, seconds);

  // Active program
  int? get activeProgramId => _prefs.getInt(_keyActiveProgramId);
  Future<void> setActiveProgramId(int id) =>
      _prefs.setInt(_keyActiveProgramId, id);
  Future<void> clearActiveProgramId() => _prefs.remove(_keyActiveProgramId);
}
