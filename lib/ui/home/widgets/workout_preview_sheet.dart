import "package:material_ui/material_ui.dart";
import "package:phosphor_icons/phosphor_icons.dart";
import "package:workout_tracker/core/widgets/exercise_side_badge.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/models/programs.dart";
import "package:workout_tracker/utils/format_time.dart";

/// Read-only preview of a workout with shortcuts to edit it, start it or open
/// its program. Each action closes the sheet before running its callback.
class WorkoutPreviewSheet extends StatelessWidget {
  const new({
    super.key,
    required this.workout,
    required this.programName,
    required this.onEdit,
    required this.onStart,
    required this.onOpenProgram,
  });

  final WorkoutWithExercises workout;
  final String programName;
  final VoidCallback onEdit;
  final VoidCallback onStart;
  final VoidCallback onOpenProgram;

  void _closeThen(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final details = workout.workout;
    final exercises = workout.exercises;
    final isChallenge = details.kind == WorkoutKind.challenge;
    final restSeconds = details.restDurationSeconds;
    final mutedSmall = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Day ${details.position + 1} · $programName",
                          style: mutedSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          details.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (isChallenge)
                              "Challenge"
                            else
                              "${details.sets} set${details.sets == 1 ? "" : "s"}",
                            "${exercises.length} exercise${exercises.length == 1 ? "" : "s"}",
                            if (!isChallenge && restSeconds != null)
                              "${formatDuration(Duration(seconds: restSeconds))} rest",
                          ].join(" · "),
                          style: mutedSmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: "Edit workout",
                    onPressed: () => _closeThen(context, onEdit),
                    icon: const PhosphorIcon(PhosphorIconsDuotone.pencilSimple),
                  ),
                  IconButton(
                    tooltip: "Open program",
                    onPressed: () => _closeThen(context, onOpenProgram),
                    icon: const PhosphorIcon(PhosphorIconsDuotone.folderOpen),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(),
              ),
              Flexible(
                child: exercises.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          "No exercises yet",
                          textAlign: TextAlign.center,
                          style: mutedSmall,
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: exercises.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          return Row(
                            children: [
                              PhosphorIcon(
                                PhosphorIconsDuotone.barbell,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ExerciseTitleWithSide(
                                  name: exercise.exercise.name,
                                  side: exercise.side,
                                ),
                              ),
                              Text(exercise.targetLabel, style: mutedSmall),
                            ],
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _closeThen(context, onStart),
                icon: const PhosphorIcon(PhosphorIconsDuotone.play, size: 18),
                label: Text(isChallenge ? "Open challenge" : "Start workout"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
