import "package:flutter/material.dart";
import "package:workout_tracker/core/widgets/exercise_side_badge.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/ui/session/view_models/workout_session_view_model.dart";
import "package:workout_tracker/utils/format_time.dart";

class SessionBottomPanel extends StatelessWidget {
  const new({super.key, required this.vm});

  final WorkoutSessionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final isActive = vm.phase == SessionPhase.exercising;
    final isRest = vm.phase == SessionPhase.resting;
    final isLast = vm.nextExercise == null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.15)),
        ),
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          // Current
          Text(
            "NOW",
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.primary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ExerciseTitleWithSide(
                  name: isRest ? "Rest" : vm.currentExercise.exercise.name,
                  side: isRest ? ExerciseSide.both : vm.currentSide,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isRest) ...[
                if (vm.isCurrentExerciseDuration) ...[
                  const SizedBox(height: 4),
                  Text(
                    formatDuration(
                      Duration(seconds: vm.durationSecondsRemaining),
                    ),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  Text(
                    vm.currentExercise.targetLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Next
          Text(
            "NEXT",
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          vm.nextExercise != null
              ? Row(
                  children: [
                    Expanded(
                      child: ExerciseTitleWithSide(
                        name: vm.nextExercise!.exercise.name,
                        side: vm.nextSide,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      vm.nextExercise!.targetLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : Text(
                  "Last one — finish strong",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: isActive ? vm.advance : null,
              label: Text(isLast ? "Finish workout" : "Done, next"),
              icon: !isLast ? const Icon(Icons.arrow_forward_rounded) : null,
              iconAlignment: .end,
            ),
          ),
        ],
      ),
    );
  }
}
