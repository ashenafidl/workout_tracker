import "dart:async";

import "package:flutter/foundation.dart";
import "package:intl/intl.dart";
import "package:workout_tracker/data/models/session_history.dart";
import "package:workout_tracker/data/repositories/session_repo.dart";

class HistoryViewModel extends ChangeNotifier {
  new(this._sessionRepository) {
    _subscription = _sessionRepository.watchSessionHistory().listen((sessions) {
      _sessions = sessions;
      _isLoading = false;
      notifyListeners();
    });
  }

  final SessionRepository _sessionRepository;
  StreamSubscription<List<SessionHistoryEntry>>? _subscription;

  List<SessionHistoryEntry> _sessions = [];
  List<SessionHistoryEntry> get sessions => _sessions;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Map<String, List<SessionHistoryEntry>> get groupedSessions {
    final groups = <String, List<SessionHistoryEntry>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final entry in _sessions) {
      final completedAt = entry.session.completedAt!;
      final date = DateTime(
        completedAt.year,
        completedAt.month,
        completedAt.day,
      );
      final label = date == today
          ? "Today"
          : date == yesterday
          ? "Yesterday"
          : DateFormat("EEE d MMM").format(date);
      groups.putIfAbsent(label, () => []).add(entry);
    }
    return groups;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
