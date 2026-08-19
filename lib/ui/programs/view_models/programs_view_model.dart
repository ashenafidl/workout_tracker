import "dart:async";

import "package:flutter/foundation.dart";
import "package:workout_tracker/data/models/programs.dart";
import "package:workout_tracker/data/repositories/program_repo.dart";

class ProgramsViewModel extends ChangeNotifier {
  new(this._programRepository) {
    _subscribeToPrograms();
  }

  final ProgramRepo _programRepository;

  StreamSubscription<List<ProgramWithWorkoutCount>>? _programsSub;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<ProgramWithWorkoutCount> _programs = [];
  List<ProgramWithWorkoutCount> get programs => _programs;

  void _subscribeToPrograms() {
    _programsSub = _programRepository.watchPrograms().listen((list) {
      _programs = list;
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _programsSub?.cancel();
    super.dispose();
  }
}
