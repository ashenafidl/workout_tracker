import "dart:async";

import "package:flutter/foundation.dart";
import "package:workout_tracker/data/repositories/exercise_repo.dart";
import "package:workout_tracker/data/services/shared_preference_service.dart";

class MoreViewModel extends ChangeNotifier {
  new(this._exerciseRepository, this._settings) {
    _subscribeToExerciseCount();
  }

  final ExerciseRepo _exerciseRepository;
  final SharedPreferenceService _settings;

  StreamSubscription<int>? _exerciseCountSub;

  int _exerciseCount = 0;
  int get exerciseCount => _exerciseCount;

  int get restDuration => _settings.restDurationSeconds;
  Future<void> setRestDuration(int seconds) async {
    await _settings.setRestDurationSeconds(seconds);
    notifyListeners();
  }

  void _subscribeToExerciseCount() {
    _exerciseCountSub = _exerciseRepository.watchExerciseCount().listen((
      count,
    ) {
      _exerciseCount = count;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _exerciseCountSub?.cancel();
    super.dispose();
  }
}
