import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/data/models/session_history.dart";
import "package:workout_tracker/ui/history/view_models/history_view_model.dart";
import "package:workout_tracker/utils/format_time.dart";

class HistoryScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = getIt<HistoryViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: .min,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 56,
                    color: Theme.of(context).disabledColor,
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "No completed workouts yet. Start a program to begin tracking.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          final sections = vm.groupedSessions.entries.toList();
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              return _HistorySection(
                label: section.key,
                sessions: section.value,
              );
            },
          );
        },
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const new({required this.label, required this.sessions});

  final String label;
  final List<SessionHistoryEntry> sessions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
        for (final session in sessions) _SessionCard(entry: session),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const new({required this.entry});

  final SessionHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final completedAt = entry.session.completedAt!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.workoutName,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.programName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat("HH:mm").format(completedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _Stat(
                  icon: Icons.timer_outlined,
                  text: formatDuration(entry.duration),
                ),
                _Stat(
                  icon: Icons.repeat_rounded,
                  text: "${entry.circuitCount} circuits",
                ),
                _Stat(
                  icon: Icons.fitness_center,
                  text: "${entry.exerciseCount} exercises",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const new({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
