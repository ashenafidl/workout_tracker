import "dart:async";

import "package:flutter/foundation.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/models/programs.dart";
import "package:workout_tracker/data/repositories/program_repo.dart";
import "package:workout_tracker/data/repositories/workout_repo.dart";
import "package:workout_tracker/database/database.dart";

class ProgramDetailViewModel extends ChangeNotifier {
  ProgramDetailViewModel(this._programRepo, this._workoutRepo);

  final ProgramRepo _programRepo;
  final WorkoutRepo _workoutRepo;

  StreamSubscription<List<WorkoutWithExercises>>? _workoutsSub;
  StreamSubscription<List<ProgramWithWorkoutCount>>? _programSub;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Program? _program;
  Program? get program => _program;

  List<WorkoutWithExercises> _workouts = [];
  List<WorkoutWithExercises> get workouts => _workouts;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int? _programId;

  void loadProgram(int programId) {
    _programId = programId;
    _subscribeToWorkouts();
    _subscribeToProgram();
  }

  void _subscribeToWorkouts() {
    _workoutsSub?.cancel();
    _workoutsSub = _workoutRepo.watchWorkoutsForProgram(_programId!).listen((
      list,
    ) {
      _workouts = list;
      _isLoading = false;
      notifyListeners();
    });
  }

  void _subscribeToProgram() {
    _programSub?.cancel();
    _programSub = _programRepo.watchPrograms().listen((list) {
      final match = list.where((p) => p.program.id == _programId);
      if (match.isNotEmpty) {
        _program = match.first.program;
      }
      notifyListeners();
    });
  }

  Future<void> renameProgram(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      _errorMessage = "Program name is required";
      notifyListeners();
      return;
    }

    try {
      await _programRepo.updateProgram(id: _programId!, name: trimmed);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst("Exception: ", "");
    }
    notifyListeners();
  }

  Future<bool> deleteProgram() async {
    try {
      await _programRepo.deleteProgram(_programId!);
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst("Exception: ", "");
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteWorkout(int workoutId) async {
    try {
      await _workoutRepo.deleteWorkout(workoutId);
    } catch (error) {
      _errorMessage = error.toString().replaceFirst("Exception: ", "");
      notifyListeners();
    }
  }

  Future<void> setActive(int id) async {
    await _programRepo.setActiveProgram(id);
  }

  @override
  void dispose() {
    _workoutsSub?.cancel();
    _programSub?.cancel();
    super.dispose();
  }
}
