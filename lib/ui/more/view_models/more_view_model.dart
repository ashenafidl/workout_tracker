import "dart:async";

import "package:flutter/foundation.dart";
import "package:workout_tracker/data/repositories/exercise_repo.dart";
import "package:workout_tracker/data/services/backup_service.dart";
import "package:workout_tracker/data/services/shared_preference_service.dart";

class MoreViewModel extends ChangeNotifier {
  new(this._exerciseRepository, this._settings, this._backupService) {
    _subscribeToExerciseCount();
  }

  final ExerciseRepo _exerciseRepository;
  final SharedPreferenceService _settings;
  final BackupService _backupService;

  StreamSubscription<int?>? _exerciseCountSub;

  bool _isBackupBusy = false;
  bool get isBackupBusy => _isBackupBusy;

  int _exerciseCount = 0;
  int get exerciseCount => _exerciseCount;

  int get restDuration => _settings.restDurationSeconds;
  Future<void> setRestDuration(int seconds) async {
    await _settings.setRestDurationSeconds(seconds);
    notifyListeners();
  }

  Future<bool> exportBackup() =>
      _runBackupOperation(_backupService.exportBackup);

  Future<BackupContents?> selectBackup() =>
      _runBackupOperation(_backupService.selectBackup);

  Future<void> restoreBackup(BackupContents backup) =>
      _runBackupOperation(() => _backupService.restoreBackup(backup));

  Future<T> _runBackupOperation<T>(Future<T> Function() operation) async {
    if (_isBackupBusy) {
      throw StateError("A backup operation is already in progress.");
    }
    _isBackupBusy = true;
    notifyListeners();
    try {
      return await operation();
    } finally {
      _isBackupBusy = false;
      notifyListeners();
    }
  }

  void _subscribeToExerciseCount() {
    _exerciseCountSub = _exerciseRepository.watchExerciseCount().listen((
      count,
    ) {
      _exerciseCount = count ?? 0;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _exerciseCountSub?.cancel();
    super.dispose();
  }
}
