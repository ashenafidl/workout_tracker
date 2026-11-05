import "dart:async";

import "package:flutter/foundation.dart";
import "package:workout_tracker/data/models/workout_schedule.dart";
import "package:workout_tracker/data/repositories/schedule_repo.dart";

class ScheduleViewModel extends ChangeNotifier {
  new(this._scheduleRepo) {
    _scheduleSub = _scheduleRepo.watchSchedule().listen((schedule) {
      _savedWeekdays = schedule.weekdaysOn(DateTime.now());
      if (!_isEditing) {
        _weekdays = _savedWeekdays.toSet();
      }
      notifyListeners();
    });
  }

  final ScheduleRepo _scheduleRepo;
  StreamSubscription<WorkoutSchedule>? _scheduleSub;

  Set<int> _weekdays = {1, 2, 3, 4, 5, 6, 7};
  Set<int> _savedWeekdays = {1, 2, 3, 4, 5, 6, 7};
  bool _isEditing = false;
  bool _isSaving = false;

  Set<int> get weekdays => _weekdays;
  bool get isSaving => _isSaving;

  String? errorMessage;

  Future<void> beginEditing() async {
    final schedule = await _scheduleRepo.load();
    _savedWeekdays = schedule.weekdaysOn(DateTime.now());
    _weekdays = _savedWeekdays.toSet();
    _isEditing = true;
    errorMessage = null;
    notifyListeners();
  }

  void cancelEditing() {
    if (!_isEditing) return;
    _weekdays = _savedWeekdays.toSet();
    _isEditing = false;
    errorMessage = null;
    notifyListeners();
  }

  void toggle(int weekday) {
    if (weekday < 1 || weekday > 7) return;

    final next = _weekdays.toSet();
    if (next.contains(weekday)) {
      next.remove(weekday);
    } else {
      next.add(weekday);
    }

    if (next.isEmpty) {
      errorMessage = "Pick at least one workout day";
      notifyListeners();
      return;
    }

    errorMessage = null;
    _weekdays = next;
    notifyListeners();
  }

  Future<bool> save() async {
    if (_isSaving) return false;
    _isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _scheduleRepo.setWeekdays(_weekdays);
      _savedWeekdays = _weekdays.toSet();
      _isEditing = false;
      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _scheduleSub?.cancel();
    super.dispose();
  }
}
