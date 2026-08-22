import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/models/workout_session_args.dart";

class TodaysWorkoutCard extends StatelessWidget {
  const new({
    super.key,
    required this.workout,
    required this.programName,
    required this.totalWorkouts,
    required this.isDoneToday,
  });

  final WorkoutWithExercises workout;
  final String programName;
  final int totalWorkouts;
  final bool isDoneToday;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isDoneToday
            ? _buildDoneState(context)
            : _buildPendingState(context),
      ),
    );
  }

  Widget _buildPendingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final exercises = workout.exercises;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Today's workout",
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          workout.workout.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Day ${workout.workout.position + 1} · $programName",
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(),
        ),
        for (final exercise in exercises.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(exercise.exercise.name)),
                Text(
                  "${exercise.reps} reps",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        if (exercises.length > 3)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              "+${exercises.length - 3} more",
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Text(
          "${workout.workout.sets} sets · circuit training",
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _start(context),
            child: const Text("Start workout"),
          ),
        ),
      ],
    );
  }

  Widget _buildDoneState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final exercises = workout.exercises;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's workout",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    workout.workout.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Day ${workout.workout.position + 1} · $programName",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle_rounded,
              color: colorScheme.primary,
              size: 36,
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(),
        ),
        // Stats row
        Row(
          children: [
            _StatChip(
              icon: Icons.repeat_rounded,
              label: "${workout.workout.sets} sets",
            ),
            const SizedBox(width: 8),
            _StatChip(
              icon: Icons.fitness_center_outlined,
              label: "${exercises.length} exercises",
            ),
          ],
        ),
      ],
    );
  }

  void _start(BuildContext context) {
    context.push(
      "/session",
      extra: WorkoutSessionArgs(
        workoutWithExercises: workout,
        programId: workout.workout.programId,
        workoutIndex: workout.workout.position,
        totalWorkoutsInProgram: totalWorkouts,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const new({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
