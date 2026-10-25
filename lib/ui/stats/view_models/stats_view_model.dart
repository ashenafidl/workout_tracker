import "dart:async";

import "package:flutter/foundation.dart";
import "package:workout_tracker/data/models/stats.dart";
import "package:workout_tracker/data/repositories/session_repo.dart";
import "package:workout_tracker/data/repositories/stats_repo.dart";
import "package:workout_tracker/database/database.dart";

class StatsViewModel extends ChangeNotifier {
  new(this._statsRepo, this._sessionRepo) {
    _sessionsSubscription = _sessionRepo.watchCompletedSessions().listen(
      (sessions) {
        _sessions = sessions;
        unawaited(_loadStats());
      },
      onError: (Object error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  final StatsRepo _statsRepo;
  final SessionRepo _sessionRepo;
  StreamSubscription<List<WorkoutSession>>? _sessionsSubscription;
  List<WorkoutSession> _sessions = [];

  StatsSnapshot? _stats;
  StatsSnapshot? get stats => _stats;
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  final bool _isSavingWeight = false;
  bool get isSavingWeight => _isSavingWeight;

  void refresh() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    unawaited(_loadStats());
  }

  Future<void> _loadStats() async {
    try {
      _stats = await _statsRepo.loadStats(_sessions);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sessionsSubscription?.cancel();
    super.dispose();
  }
}
