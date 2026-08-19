import "package:flutter/material.dart";
import "package:workout_tracker/utils/format_time.dart";

class RestView extends StatelessWidget {
  const new({
    super.key,
    required this.secondsRemaining,
    required this.nextCircuit,
    required this.totalCircuits,
    required this.onSkip,
  });

  final int secondsRemaining;
  final int nextCircuit;
  final int totalCircuits;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: .min,
        children: [
          Text(
            "Rest",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatDuration(Duration(seconds: secondsRemaining)),
            key: ValueKey(secondsRemaining),
            style: Theme.of(context).textTheme.displayLarge
                ?.copyWith(fontWeight: FontWeight.bold, fontSize: 80),
          ),
          const SizedBox(height: 16),
          Text(
            "Circuit $nextCircuit of $totalCircuits coming up",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onSkip, child: const Text("Skip rest")),
        ],
      ),
    );
  }
}
