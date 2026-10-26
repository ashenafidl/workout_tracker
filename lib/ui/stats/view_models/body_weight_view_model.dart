import "dart:async";

import "package:flutter/foundation.dart";
import "package:workout_tracker/data/models/body_weight_entry.dart";
import "package:workout_tracker/data/repositories/body_weight_repo.dart";
import "package:workout_tracker/database/database.dart";

enum WeightTimeRange { month1, month3, month6, yearAll }

class BodyWeightViewModel extends ChangeNotifier {
  new(this._repo) {
    _subscription = _repo.watchAll().listen(
      (logs) {
        entries = logs.map(BodyWeightEntry.fromLog).toList();
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        isLoading = false;
        errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  final BodyWeightRepo _repo;
  StreamSubscription<List<BodyWeightLog>>? _subscription;

  List<BodyWeightEntry> entries = [];
  bool isLoading = true;
  String? errorMessage;
  WeightTimeRange selectedRange = WeightTimeRange.month1;

  BodyWeightEntry? get latest => entries.isEmpty ? null : entries.last;

  BodyWeightEntry? get lowest {
    if (entries.isEmpty) return null;
    return entries.reduce((a, b) => a.weightKg <= b.weightKg ? a : b);
  }

  BodyWeightEntry? get highest {
    if (entries.isEmpty) return null;
    return entries.reduce((a, b) => a.weightKg >= b.weightKg ? a : b);
  }

  double? get changeFromFirst {
    final last = latest;
    return last == null ? null : last.weightKg - entries.first.weightKg;
  }

  List<BodyWeightEntry> get filteredEntries {
    if (selectedRange == WeightTimeRange.yearAll) return entries;
    final now = DateTime.now();
    final days = switch (selectedRange) {
      WeightTimeRange.month1 => 30,
      WeightTimeRange.month3 => 90,
      WeightTimeRange.month6 => 180,
      WeightTimeRange.yearAll => throw StateError("Range handled above"),
    };
    final cutoff = now.subtract(Duration(days: days));
    return entries.where((entry) => !entry.loggedAt.isBefore(cutoff)).toList();
  }

  void setRange(WeightTimeRange range) {
    selectedRange = range;
    notifyListeners();
  }

  Future<BodyWeightEntry?> getLatest() async {
    final log = await _repo.getLatest();
    return log == null ? null : BodyWeightEntry.fromLog(log);
  }

  Future<void> add(double weightKg) async {
    errorMessage = null;
    try {
      await _repo.add(weightKg: weightKg);
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> update(int id, double weightKg) async {
    errorMessage = null;
    try {
      await _repo.update(id: id, weightKg: weightKg);
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
