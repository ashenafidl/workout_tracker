import "dart:async";

import "package:flutter/foundation.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/repositories/exercise_repo.dart";

class ExerciseListViewModel extends ChangeNotifier {
  new(this._exerciseRepository) {
    _subscribeToExercises();
  }

  final ExerciseRepo _exerciseRepository;

  StreamSubscription<List<ExerciseWithTypes>>? _exercisesSub;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<ExerciseWithTypes> _exercises = [];
  List<ExerciseWithTypes> get exercises => _exercises;

  void _subscribeToExercises() {
    _exercisesSub = _exerciseRepository.watchAllExercisesWithTypes().listen((
      list,
    ) {
      _exercises = list;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> deleteExercise(int id) async {
    try {
      await _exerciseRepository.deleteExercise(id);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _exercisesSub?.cancel();
    super.dispose();
  }
}
