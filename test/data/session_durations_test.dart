import "package:flutter_test/flutter_test.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/services/session_durations.dart";
import "package:workout_tracker/database/database.dart";

final _start = DateTime(2026, 11, 24, 8);

DateTime _at(int minutes, [int seconds = 0]) =>
    _start.add(Duration(minutes: minutes, seconds: seconds));

var _nextId = 1;

ChallengeLog _reps(DateTime at, [int reps = 10]) => ChallengeLog(
  id: _nextId++,
  sessionId: 1,
  exerciseId: 1,
  exerciseType: ExerciseType.reps,
  reps: reps,
  loggedAt: at,
);

ChallengeLog _timed(DateTime endedAt, int seconds) => ChallengeLog(
  id: _nextId++,
  sessionId: 1,
  exerciseId: 2,
  exerciseType: ExerciseType.duration,
  durationSeconds: seconds,
  loggedAt: endedAt,
);

ChallengeScreenVisit _visit(DateTime openedAt, DateTime closedAt) =>
    ChallengeScreenVisit(
      id: _nextId++,
      sessionId: 1,
      openedAt: openedAt,
      closedAt: closedAt,
    );

SessionCircuit _circuit(
  int number,
  DateTime startedAt,
  DateTime? completedAt,
) => SessionCircuit(
  id: number,
  sessionId: 1,
  circuitNumber: number,
  startedAt: startedAt,
  completedAt: completedAt,
);

void main() {
  group("circuit sessions", () {
    test("rest is the gap between circuits and workout the remainder", () {
      final durations = SessionDurations.forCircuitSession(
        startedAt: _at(0),
        completedAt: _at(25),
        circuits: [_circuit(2, _at(12), _at(25)), _circuit(1, _at(0), _at(10))],
      );

      expect(durations.rest, const Duration(minutes: 2));
      expect(durations.workout, const Duration(minutes: 23));
      expect(durations.total, const Duration(minutes: 25));
    });

    test("ignores unfinished circuits and negative gaps", () {
      final durations = SessionDurations.forCircuitSession(
        startedAt: _at(0),
        completedAt: _at(10),
        circuits: [
          _circuit(1, _at(0), null),
          _circuit(2, _at(5), _at(8)),
          _circuit(3, _at(7), _at(10)),
        ],
      );

      expect(durations.rest, Duration.zero);
      expect(durations.workout, const Duration(minutes: 10));
    });
  });

  group("challenge sessions", () {
    test("timed-only challenges sum their entries", () {
      final durations = SessionDurations.forChallengeSession(
        logs: [_timed(_at(1), 60), _timed(_at(400), 90)],
        visits: [_visit(_at(0), _at(1)), _visit(_at(398), _at(400))],
      );

      expect(durations.workout, const Duration(seconds: 150));
      expect(durations.rest, Duration.zero);
    });

    test("rep challenges skip time the screen was closed", () {
      // 08:00 open, log at 08:05 and 08:20, close; reopen at 14:20, log at
      // 14:25 and 14:30.
      final durations = SessionDurations.forChallengeSession(
        logs: [_reps(_at(5)), _reps(_at(20)), _reps(_at(385)), _reps(_at(390))],
        visits: [_visit(_at(0), _at(20)), _visit(_at(380), _at(390))],
      );

      // 08:05-08:20 plus 14:20-14:30; the 6 hours away are not counted.
      expect(durations.workout, const Duration(minutes: 25));
    });

    test("mixed challenges count timed entries and on-screen span once", () {
      final durations = SessionDurations.forChallengeSession(
        logs: [
          _timed(_at(2), 60), // 08:01-08:02, inside the rep span
          _reps(_at(10)),
          _timed(_at(301), 60), // 13:00-13:01, after a long gap
          _reps(_at(305)),
        ],
        visits: [_visit(_at(0), _at(10)), _visit(_at(300), _at(305))],
      );

      // 08:01-08:10 (9 min) plus 13:00-13:05 (5 min).
      expect(durations.workout, const Duration(minutes: 14));
    });

    test("sessions without visits fall back to the full span", () {
      final durations = SessionDurations.forChallengeSession(
        logs: [_reps(_at(0)), _reps(_at(30))],
        visits: const [],
      );

      expect(durations.workout, const Duration(minutes: 30));
    });

    test("no logs means no time", () {
      final durations = SessionDurations.forChallengeSession(
        logs: const [],
        visits: [_visit(_at(0), _at(5))],
      );

      expect(durations, isA<SessionDurations>());
      expect(durations.total, Duration.zero);
    });
  });
}
