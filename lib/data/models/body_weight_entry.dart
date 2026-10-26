import "package:workout_tracker/database/database.dart";

class BodyWeightEntry {
  const new({required this.id, required this.weightKg, required this.loggedAt});

  final int id;
  final double weightKg;
  final DateTime loggedAt;

  factory fromLog(BodyWeightLog log) => BodyWeightEntry(
    id: log.id,
    weightKg: log.weightKg,
    loggedAt: log.loggedAt,
  );
}
