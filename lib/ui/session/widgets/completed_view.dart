import "package:flutter/material.dart";
import "package:workout_tracker/data/models/session_summary.dart";
import "package:workout_tracker/utils/format_time.dart";

class CompletedView extends StatelessWidget {
  const new({super.key, required this.summary, required this.onDone});

  final WorkoutSessionSummary? summary;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.check_circle_rounded, size: 72, color: cs.primary),
            const SizedBox(height: 16),
            Text(
              "Workout complete",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              summary!.workoutName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _SummaryTile(
              label: "Total duration",
              value: formatDuration(summary!.totalDuration),
            ),
            const SizedBox(height: 8),
            _SummaryTile(
              label: "Rest time",
              value: formatDuration(summary!.totalRestDuration),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: summary!.circuits.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final circuit = summary!.circuits[index];
                  return _CircuitSummaryCard(circuit: circuit);
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(onPressed: onDone, child: const Text("Done")),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _CircuitSummaryCard extends StatelessWidget {
  const new({required this.circuit});

  final CircuitSummary circuit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Circuit ${circuit.circuitNumber}",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Duration: ${formatDuration(circuit.duration)} • Rest: ${formatDuration(circuit.restDuration)}",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...circuit.exercises.map(
              (exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      "${exercise.actualReps}/${exercise.targetReps}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
