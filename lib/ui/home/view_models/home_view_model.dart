import "dart:async";

import "package:flutter/foundation.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/repositories/program_repo.dart";
import "package:workout_tracker/data/repositories/workout_repo.dart";
import "package:workout_tracker/database/database.dart";

class HomeViewModel extends ChangeNotifier {
  new(this._programRepo, this._workoutRepo) {
    _activeProgramSub = _programRepo.watchActiveProgram().listen((program) {
      _activeProgram = program;
      _sessionsSub?.cancel();
      _workoutsSub?.cancel();
      _completedSessions = [];
      _workouts = [];
      _todaysWorkout = null;
      _isDoneToday = false;

      if (program != null) {
        _sessionsSub = _workoutRepo
            .watchCompletedSessionsForProgram(program.id)
            .listen((sessions) {
              _completedSessions = sessions;
              _recompute();
            });
        _workoutsSub = _workoutRepo.watchWorkoutsForProgram(program.id).listen((
          workouts,
        ) {
          _workouts = workouts;
          _recompute();
        });
      }
      _isLoading = program != null;
      notifyListeners();
    });
  }

  final ProgramRepo _programRepo;
  final WorkoutRepo _workoutRepo;
  StreamSubscription<Program?>? _activeProgramSub;
  StreamSubscription<List<WorkoutSession>>? _sessionsSub;
  StreamSubscription<List<WorkoutWithExercises>>? _workoutsSub;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Program? _activeProgram;
  Program? get activeProgram => _activeProgram;

  List<WorkoutSession> _completedSessions = [];
  List<WorkoutWithExercises> _workouts = [];
  int get totalWorkouts => _workouts.length;
  WorkoutWithExercises? _todaysWorkout;
  WorkoutWithExercises? get todaysWorkout => _todaysWorkout;

  bool _isDoneToday = false;
  bool get isDoneToday => _isDoneToday;

  void _recompute() {
    final program = _activeProgram;
    if (program == null) {
      _todaysWorkout = null;
      _isDoneToday = false;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Each workout represents one day: once a workout is completed today it
    // stays on the card marked as done until tomorrow, instead of advancing
    // straight to the next workout in the program.
    final todaysSession = _completedSessions.firstWhereOrNull(
      (session) =>
          session.completedAt != null && _isToday(session.completedAt!),
    );
    final doneToday = todaysSession == null
        ? null
        : _workouts.firstWhereOrNull(
            (workout) => workout.workout.id == todaysSession.workoutId,
          );

    if (doneToday != null) {
      _todaysWorkout = doneToday;
      _isDoneToday = true;
      _isLoading = false;
      notifyListeners();
      return;
    }

    final completedIds = _completedSessions
        .map((session) => session.workoutId)
        .toSet();
    final next = _workouts.firstWhereOrNull(
      (workout) => !completedIds.contains(workout.workout.id),
    );
    _todaysWorkout = next ?? (_workouts.isEmpty ? null : _workouts.first);
    _isDoneToday = false;
    _isLoading = false;
    notifyListeners();
  }

  bool _isToday(DateTime value) {
    final now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  @override
  void dispose() {
    _activeProgramSub?.cancel();
    _sessionsSub?.cancel();
    _workoutsSub?.cancel();
    super.dispose();
  }
}

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T value) test) {
    for (final value in this) {
      if (test(value)) return value;
    }
    return null;
  }
}
