import "dart:async";

import "package:flutter/foundation.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/repositories/exercise_repository.dart";
import "package:workout_tracker/data/repositories/workout_repository.dart";
import "package:workout_tracker/database/database.dart";

class WorkoutSheetViewModel extends ChangeNotifier {
  WorkoutSheetViewModel(this._workoutRepository, this._exerciseRepository);

  final WorkoutRepository _workoutRepository;
  final ExerciseRepository _exerciseRepository;

  int? _workoutId;
  bool get isEditing => _workoutId != null;

  String _name = "";
  String get name => _name;
  set name(String value) {
    _name = value;
    notifyListeners();
  }

  int _sets = 1;
  int get sets => _sets;
  set sets(int value) {
    _sets = value;
    notifyListeners();
  }

  List<WorkoutExerciseInput> _exercises = [];
  List<WorkoutExerciseInput> get exercises => _exercises;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void loadWorkout({
    required int workoutId,
    required String name,
    required int sets,
    required List<WorkoutExerciseDetail> exercises,
  }) {
    _workoutId = workoutId;
    _name = name;
    _sets = sets;
    _exercises = exercises
        .map(
          (e) => WorkoutExerciseInput(
            exerciseId: e.exercise.id,
            exerciseName: e.exercise.name,
            reps: e.reps,
            position: e.position,
          ),
        )
        .toList();
    notifyListeners();
  }

  void addExercise(Exercise exercise) {
    final position = _exercises.length;
    _exercises = List.from(_exercises)
      ..add(
        WorkoutExerciseInput(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          reps: 10,
          position: position,
        ),
      );
    notifyListeners();
  }

  void removeExercise(int index) {
    _exercises = List.from(_exercises)..removeAt(index);
    _reindexExercises();
    notifyListeners();
  }

  void updateExerciseReps(int index, int reps) {
    final old = _exercises[index];
    _exercises = List.from(_exercises)
      ..[index] = WorkoutExerciseInput(
        exerciseId: old.exerciseId,
        exerciseName: old.exerciseName,
        reps: reps,
        position: old.position,
      );
    notifyListeners();
  }

  void reorderExercises(int oldIndex, int newIndex) {
    final item = _exercises[oldIndex];
    _exercises = List.from(_exercises)
      ..removeAt(oldIndex)
      ..insert(newIndex, item);
    _reindexExercises();
    notifyListeners();
  }

  void _reindexExercises() {
    _exercises = _exercises.asMap().entries.map((entry) {
      final old = entry.value;
      return WorkoutExerciseInput(
        exerciseId: old.exerciseId,
        exerciseName: old.exerciseName,
        reps: old.reps,
        position: entry.key,
      );
    }).toList();
  }

  Future<Exercise?> createAndAddExercise(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      await _exerciseRepository.addExercise(name: trimmed);
      final completer = Completer<Exercise?>();
      late final StreamSubscription<List<Exercise>> sub;
      sub = _exerciseRepository.watchAllExercises().listen((exercises) {
        final match = exercises.where((e) => e.name == trimmed).toList();
        if (match.isNotEmpty && !completer.isCompleted) {
          completer.complete(match.first);
          sub.cancel();
        }
      });

      Future.delayed(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          sub.cancel();
          completer.complete(null);
        }
      });

      return completer.future;
    } catch (_) {
      return null;
    }
  }

  Future<bool> submit(String programId) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = "Workout name is required";
      notifyListeners();
      return false;
    }

    if (_exercises.isEmpty) {
      _errorMessage = "Add at least one exercise";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isEditing) {
        await _workoutRepository.updateWorkout(
          workoutId: _workoutId!,
          name: trimmedName,
          sets: _sets,
          exercises: _exercises,
        );
      } else {
        await _workoutRepository.addWorkout(
          programId: programId,
          name: trimmedName,
          sets: _sets,
          exercises: _exercises,
        );
      }
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst("Exception: ", "");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
