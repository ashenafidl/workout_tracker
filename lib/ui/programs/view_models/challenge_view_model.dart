import "dart:async";

import "package:flutter/foundation.dart";
import "package:workout_tracker/data/models/challenge.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/repositories/challenge_repo.dart";
import "package:workout_tracker/data/services/shared_preference_service.dart";
import "package:workout_tracker/data/services/streak_service.dart";

class ChallengeViewModel extends ChangeNotifier {
  new(this._challengeRepo, this._streakService, this._preferenceService);

  final ChallengeRepo _challengeRepo;
  final StreakService _streakService;
  final SharedPreferenceService _preferenceService;

  StreamSubscription<List<ChallengeExerciseProgress>>? _progressSub;

  int? _sessionId;
  int? get sessionId => _sessionId;

  List<ChallengeExerciseProgress> _progress = [];
  List<ChallengeExerciseProgress> get progress => _progress;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> init(WorkoutWithExercises workout, int programId) async {
    try {
      final sessionId = await _challengeRepo.getOrCreateTodaySession(
        workout.workout.id,
        programId,
        since: _preferenceService.programRunStartForProgram(programId),
      );
      _sessionId = sessionId;
      _isCompleted = await _challengeRepo.isSessionCompleted(sessionId);

      _progressSub?.cancel();
      _progressSub = _challengeRepo
          .watchProgress(sessionId, workout.workout.id)
          .listen((progress) {
            _progress = progress;
            _isLoading = false;
            notifyListeners();
          });
    } catch (error) {
      _errorMessage = error.toString().replaceFirst("Exception: ", "");
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logEntry(ChallengeExerciseProgress item, int value) async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    if (item.exercise.type == ExerciseType.reps) {
      await _challengeRepo.logReps(
        sessionId: sessionId,
        exerciseId: item.exercise.id,
        exerciseType: item.exercise.type,
        side: item.side,
        reps: value,
      );
      return;
    }

    await _challengeRepo.logDuration(
      sessionId: sessionId,
      exerciseId: item.exercise.id,
      exerciseType: item.exercise.type,
      side: item.side,
      durationSeconds: value,
    );
  }

  Future<void> markDone() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    await _challengeRepo.completeSession(sessionId);
    await _streakService.recordCompletedSession(excludeSessionId: sessionId);
    _isCompleted = true;
    notifyListeners();
  }

  bool get allTargetsMet =>
      _progress.isNotEmpty && _progress.every((item) => item.isComplete);

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }
}
