import "package:flutter/foundation.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/repositories/exercise_repo.dart";

class ExerciseFormViewModel extends ChangeNotifier {
  new(this._exerciseRepository);

  final ExerciseRepo _exerciseRepository;

  int? _exerciseId;
  bool get isEditing => _exerciseId != null;

  String _name = "";
  String get name => _name;
  set name(String value) {
    _name = value;
    notifyListeners();
  }

  String _description = "";
  String get description => _description;
  set description(String value) {
    _description = value;
    notifyListeners();
  }

  Set<ExerciseType> _types = {ExerciseType.reps};
  Set<ExerciseType> get types => _types;

  void toggleType(ExerciseType value) {
    _types = Set.of(_types);
    if (_types.contains(value)) {
      _types.remove(value);
    } else {
      _types.add(value);
    }
    notifyListeners();
  }

  bool _isBilateral = false;
  bool get isBilateral => _isBilateral;
  set isBilateral(bool value) {
    _isBilateral = value;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void loadExercise(ExerciseWithTypes exerciseWithTypes) {
    final exercise = exerciseWithTypes.exercise;
    _exerciseId = exercise.id;
    _name = exercise.name;
    _description = exercise.description ?? "";
    _types = exerciseWithTypes.supportedTypes.toSet();
    _isBilateral = exercise.isBilateral;
    notifyListeners();
  }

  Future<bool> submit() async {
    final trimmedName = name.trim();
    final trimmedDescription = description.trim();

    if (trimmedName.isEmpty) {
      _errorMessage = "Name is required";
      notifyListeners();
      return false;
    }

    if (trimmedName.length > 100) {
      _errorMessage = "Name must be 100 characters or fewer";
      notifyListeners();
      return false;
    }
    if (_types.isEmpty) {
      _errorMessage = "Select at least one exercise type";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isEditing) {
        await _exerciseRepository.updateExercise(
          id: _exerciseId!,
          name: trimmedName,
          description: trimmedDescription.isEmpty ? null : trimmedDescription,
          types: types.toList(),
          isBilateral: isBilateral,
        );
      } else {
        await _exerciseRepository.addExercise(
          name: trimmedName,
          description: trimmedDescription.isEmpty ? null : trimmedDescription,
          types: types.toList(),
          isBilateral: isBilateral,
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
