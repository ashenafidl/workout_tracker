import "package:flutter/material.dart";
import "package:workout_tracker/ui/session/view_models/workout_session_view_model.dart";

class SessionProgressBar extends StatelessWidget {
  const new({super.key, required this.vm});

  final WorkoutSessionViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          for (int s = 0; s < vm.totalSets; s++) ...[
            Expanded(
              flex: s + 1 == vm.currentCircuit ? 20 : 1,
              child: s + 1 == vm.currentCircuit
                  ? _CurrentSetBar(vm: vm)
                  : _SetBar(completed: s + 1 < vm.currentCircuit),
            ),
            if (s < vm.totalSets - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _SetBar extends StatelessWidget {
  const new({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: completed ? cs.primary : cs.onSurface.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _CurrentSetBar extends StatelessWidget {
  const new({required this.vm});

  final WorkoutSessionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (int i = 0; i < vm.exercises.length; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: switch (vm.exerciseStatus(i)) {
                  SegmentStatus.completed => cs.primary,
                  SegmentStatus.current => cs.primary.withValues(alpha: .45),
                  SegmentStatus.upcoming => cs.onSurface.withValues(alpha: .12),
                },
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < vm.exercises.length - 1) const SizedBox(width: 2),
        ],
      ],
    );
  }
}
