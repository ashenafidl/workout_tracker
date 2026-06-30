import "dart:async";

import "package:flutter/foundation.dart";
import "package:workout_tracker/data/repositories/exercise_repository.dart";

class MoreViewModel extends ChangeNotifier {
  final ExerciseRepository _exerciseRepository;

  MoreViewModel(this._exerciseRepository) {
    _subscribeToExerciseCount();
  }

  StreamSubscription<int>? _exerciseCountSub;

  int _exerciseCount = 0;
  int get exerciseCount => _exerciseCount;

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
