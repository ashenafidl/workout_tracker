import "package:flutter/material.dart";
import "package:workout_tracker/data/models/exercises.dart";

/// Asks which side a bilateral exercise is performed on when it is added to a
/// workout. Returns null when dismissed, so callers can leave the exercise out
/// rather than guessing a side.
class ExerciseSideSheet extends StatefulWidget {
  const new({super.key, required this.exerciseName, required this.initialSide});

  final String exerciseName;
  final ExerciseSide initialSide;

  static Future<ExerciseSide?> show(
    BuildContext context, {
    required String exerciseName,
    ExerciseSide initialSide = ExerciseSide.both,
  }) {
    return showModalBottomSheet<ExerciseSide>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => ExerciseSideSheet(
        exerciseName: exerciseName,
        initialSide: initialSide,
      ),
    );
  }

  @override
  State<ExerciseSideSheet> createState() => _ExerciseSideSheetState();
}

class _ExerciseSideSheetState extends State<ExerciseSideSheet> {
  late ExerciseSide _selectedSide;

  @override
  void initState() {
    super.initState();
    _selectedSide = widget.initialSide;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Which side?", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            widget.exerciseName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          RadioGroup<ExerciseSide>(
            groupValue: _selectedSide,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedSide = value);
              }
            },
            child: Column(
              mainAxisSize: .min,
              children: [
                for (final option in ExerciseSide.values)
                  RadioListTile<ExerciseSide>(
                    value: option,
                    title: Text(option.name),
                    subtitle: Text(option.description),
                    secondary: Icon(option.icon),
                    controlAffinity: ListTileControlAffinity.trailing,
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _selectedSide),
              child: const Text("Continue"),
            ),
          ),
        ],
      ),
    );
  }
}
