class WorkoutSchedule {
  new(List<ScheduleChange> changes)
    : assert(changes.isNotEmpty),
      _changes = List.unmodifiable(
        List<ScheduleChange>.from(changes)
          ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom)),
      );

  final List<ScheduleChange> _changes;

  List<ScheduleChange> get changes => _changes;

  Set<int> weekdaysOn(DateTime date) {
    final normalized = _dateOnly(date);
    var latest = _changes.first;
    for (final change in _changes) {
      if (!change.effectiveFrom.isAfter(normalized)) {
        latest = change;
      }
    }
    return latest.weekdays;
  }

  bool isScheduled(DateTime date) => weekdaysOn(date).contains(date.weekday);

  DateTime? previousScheduledDay(DateTime date) {
    final normalized = _dateOnly(date);
    for (var offset = 1; offset <= 366; offset++) {
      final candidate = DateTime(
        normalized.year,
        normalized.month,
        normalized.day - offset,
      );
      if (isScheduled(candidate)) return candidate;
    }
    return null;
  }

  bool hasScheduledDayBetween(
    DateTime afterExclusive,
    DateTime beforeExclusive,
  ) {
    final lower = _dateOnly(afterExclusive);
    final upper = _dateOnly(beforeExclusive);
    if (!lower.isBefore(upper)) return false;

    for (var offset = 1; offset <= 366; offset++) {
      final candidate = DateTime(lower.year, lower.month, lower.day + offset);
      if (!candidate.isBefore(upper)) break;
      if (isScheduled(candidate)) return true;
    }
    return false;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class ScheduleChange {
  const new({required this.effectiveFrom, required this.weekdays});

  final DateTime effectiveFrom;
  final Set<int> weekdays;
}

int weekdayMaskFor(Set<int> weekdays) {
  var mask = 0;
  for (final weekday in weekdays) {
    final normalized = weekday.clamp(1, 7);
    mask |= 1 << (normalized - 1);
  }
  return mask;
}

Set<int> weekdaysFromMask(int mask) {
  final weekdays = <int>{};
  for (var weekday = 1; weekday <= 7; weekday++) {
    final bit = 1 << (weekday - 1);
    if ((mask & bit) != 0) {
      weekdays.add(weekday);
    }
  }
  return weekdays;
}
