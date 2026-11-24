import "package:workout_tracker/database/database.dart";

/// The single place that decides how long a session took and how much of it
/// was rest. History, stats, the streak calendar and the end-of-workout
/// summary all read from here.
class SessionDurations {
  const new({required this.workout, required this.rest});

  static const SessionDurations zero = SessionDurations(
    workout: Duration.zero,
    rest: Duration.zero,
  );

  /// Time spent exercising.
  final Duration workout;

  /// Time spent resting between circuits. Always zero for challenges.
  final Duration rest;

  Duration get total => workout + rest;

  /// Circuit workouts. The total is the wall-clock time from start to
  /// completion; rest is the time between one circuit finishing and the next
  /// one starting; the workout is whatever remains.
  factory forCircuitSession({
    required DateTime startedAt,
    required DateTime completedAt,
    required List<SessionCircuit> circuits,
  }) {
    final elapsed = _nonNegative(completedAt.difference(startedAt));
    final sorted = [...circuits]
      ..sort((a, b) => a.circuitNumber.compareTo(b.circuitNumber));

    var rest = Duration.zero;
    for (var index = 0; index < sorted.length - 1; index++) {
      rest += restAfterCircuit(sorted[index], sorted[index + 1]);
    }
    if (rest > elapsed) rest = elapsed;

    return SessionDurations(workout: elapsed - rest, rest: rest);
  }

  /// Challenges. Each timed entry counts for its own length (it ends at
  /// `loggedAt`). When rep entries exist, the span from the first to the last
  /// entry also counts, but only while the challenge screen was open, so time
  /// with the app closed is skipped. Overlapping time is counted once.
  ///
  /// Sessions without any recorded [visits] (logged before visits were
  /// tracked) fall back to the full first-to-last span.
  factory forChallengeSession({
    required List<ChallengeLog> logs,
    required List<ChallengeScreenVisit> visits,
  }) {
    final timed = [
      for (final log in logs)
        if ((log.durationSeconds ?? 0) > 0)
          _Range(
            log.loggedAt.subtract(Duration(seconds: log.durationSeconds!)),
            log.loggedAt,
          ),
    ];
    final repTimes = [
      for (final log in logs)
        if ((log.reps ?? 0) > 0) log.loggedAt,
    ];

    if (repTimes.isEmpty) {
      return SessionDurations(workout: _unionLength(timed), rest: .zero);
    }

    final span = _Range(
      [...timed.map((range) => range.start), ...repTimes].reduce(_earlier),
      [...timed.map((range) => range.end), ...repTimes].reduce(_later),
    );
    final windows = visits.isEmpty
        ? [span]
        : [
            for (final visit in visits)
              ?_Range(visit.openedAt, visit.closedAt).clipTo(span),
          ];

    return SessionDurations(
      workout: _unionLength([...timed, ...windows]),
      rest: .zero,
    );
  }

  /// Rest between [circuit] finishing and [next] starting.
  static Duration restAfterCircuit(
    SessionCircuit circuit,
    SessionCircuit next,
  ) {
    final completedAt = circuit.completedAt;
    if (completedAt == null) return Duration.zero;
    return _nonNegative(next.startedAt.difference(completedAt));
  }
}

class _Range {
  const new(this.start, this.end);

  final DateTime start;
  final DateTime end;

  _Range? clipTo(_Range bounds) {
    final clippedStart = _later(start, bounds.start);
    final clippedEnd = _earlier(end, bounds.end);
    if (!clippedEnd.isAfter(clippedStart)) return null;
    return _Range(clippedStart, clippedEnd);
  }
}

Duration _unionLength(List<_Range> ranges) {
  final sorted =
      ranges.where((range) => range.end.isAfter(range.start)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  var total = Duration.zero;
  DateTime? currentStart;
  DateTime? currentEnd;
  for (final range in sorted) {
    if (currentEnd != null && !range.start.isAfter(currentEnd)) {
      currentEnd = _later(currentEnd, range.end);
      continue;
    }
    if (currentStart != null && currentEnd != null) {
      total += currentEnd.difference(currentStart);
    }
    currentStart = range.start;
    currentEnd = range.end;
  }
  if (currentStart != null && currentEnd != null) {
    total += currentEnd.difference(currentStart);
  }
  return total;
}

DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
Duration _nonNegative(Duration value) =>
    value.isNegative ? Duration.zero : value;
