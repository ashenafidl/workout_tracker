import "package:flutter/foundation.dart";
import "package:workout_tracker/data/repositories/exercise_repository.dart";
import "package:workout_tracker/database/database.dart";

class ExerciseFormViewModel extends ChangeNotifier {
  ExerciseFormViewModel(this._exerciseRepository);

  final ExerciseRepository _exerciseRepository;

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

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void loadExercise(Exercise exercise) {
    _exerciseId = exercise.id;
    _name = exercise.name;
    _description = exercise.description ?? "";
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

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isEditing) {
        await _exerciseRepository.updateExercise(
          id: _exerciseId!,
          name: trimmedName,
          description: trimmedDescription.isEmpty ? null : trimmedDescription,
        );
      } else {
        await _exerciseRepository.addExercise(
          name: trimmedName,
          description: trimmedDescription.isEmpty ? null : trimmedDescription,
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
