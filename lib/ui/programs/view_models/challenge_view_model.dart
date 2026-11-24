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

  /// When the screen last came to the foreground; null while it is hidden.
  DateTime? _visibleSince = DateTime.now();

  /// The visit row for the current foreground stretch, created on its first
  /// log so stretches without activity leave nothing behind.
  int? _visitId;
  Future<void>? _visitWrite;

  void onScreenShown() {
    _visibleSince ??= DateTime.now();
  }

  void onScreenHidden() {
    _visibleSince = null;
    _visitId = null;
  }

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

    if (item.type == ExerciseType.reps) {
      await _challengeRepo.logReps(
        sessionId: sessionId,
        exerciseId: item.exercise.id,
        exerciseType: item.type,
        side: item.side,
        reps: value,
      );
    } else {
      await _challengeRepo.logDuration(
        sessionId: sessionId,
        exerciseId: item.exercise.id,
        exerciseType: item.type,
        side: item.side,
        durationSeconds: value,
      );
    }

    // After the insert, so the visit never ends before its last log.
    await _recordActivity(sessionId);
  }

  Future<void> markDone() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    await _challengeRepo.completeSession(sessionId);
    await _streakService.recordCompletedSession(excludeSessionId: sessionId);
    _isCompleted = true;
    notifyListeners();
  }

  /// Serialised so two quick logs cannot both create a visit row.
  Future<void> _recordActivity(int sessionId) {
    final previous = _visitWrite ?? Future<void>.value();
    final write = previous.then((_) async {
      final now = DateTime.now();
      final visitId = _visitId;
      if (visitId != null) {
        await _challengeRepo.extendVisit(visitId, now);
        return;
      }
      _visitId = await _challengeRepo.startVisit(
        sessionId: sessionId,
        openedAt: _visibleSince ?? now,
        lastActivityAt: now,
      );
    });
    _visitWrite = write;
    return write;
  }

  bool get allTargetsMet =>
      _progress.isNotEmpty && _progress.every((item) => item.isComplete);

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }
}
