import "package:flutter/material.dart";

/// Result from the exercise input sheet.
///
/// Currently only [RepsInputResult] is supported. Future exercise types
/// (timed, until-failure, distance) can be added as additional subclasses
/// and the sheet UI extended with a type selector.
sealed class ExerciseInputResult {
  const ExerciseInputResult();
}

/// Result containing a rep count.
class RepsInputResult extends ExerciseInputResult {
  const RepsInputResult({required this.reps});

  final int reps;
}

/// Bottom sheet for configuring exercise parameters.
///
/// Currently supports reps input with a stepper-style UI (large number
/// flanked by − / + buttons without outline/border). Returns an [ExerciseInputResult]
/// when confirmed, or `null` if dismissed.
class ExerciseInputSheet extends StatefulWidget {
  const ExerciseInputSheet({
    super.key,
    required this.exerciseName,
    this.initialReps = 10,
  });

  final String exerciseName;
  final int initialReps;

  @override
  State<ExerciseInputSheet> createState() => _ExerciseInputSheetState();
}

class _ExerciseInputSheetState extends State<ExerciseInputSheet> {
  late int _reps;

  @override
  void initState() {
    super.initState();
    _reps = widget.initialReps;
  }

  void _decrement() {
    if (_reps > 1) {
      setState(() {
        _reps--;
      });
    }
  }

  void _increment() {
    setState(() {
      _reps++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.exerciseName,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "Reps",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _reps > 1 ? _decrement : null,
                  icon: const Icon(Icons.remove_rounded),
                  iconSize: 36,
                  style: IconButton.styleFrom(minimumSize: const Size(64, 64)),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    "$_reps",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _increment,
                  icon: const Icon(Icons.add_rounded),
                  iconSize: 36,
                  style: IconButton.styleFrom(minimumSize: const Size(64, 64)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.pop(context, RepsInputResult(reps: _reps)),
                child: const Text("Done"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
