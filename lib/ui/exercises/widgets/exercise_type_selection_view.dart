import "package:flutter/material.dart";
import "package:workout_tracker/data/models/exercises.dart";

class ExerciseTypeSelectionView extends StatelessWidget {
  const new({
    super.key,
    required this.name,
    required this.description,
    required this.selectedType,
    required this.isLoading,
    required this.submitLabel,
    required this.onBack,
    required this.onTypeSelected,
    required this.onSubmit,
  });

  final String name;
  final String description;
  final ExerciseType selectedType;
  final bool isLoading;
  final String submitLabel;
  final VoidCallback onBack;
  final ValueChanged<ExerciseType> onTypeSelected;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: isLoading ? null : onBack,
              icon: const Icon(Icons.arrow_back),
              tooltip: "Back",
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleLarge),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        RadioGroup(
          groupValue: selectedType,
          onChanged: (value) {
            if (value != null) {
              onTypeSelected(value);
            }
          },
          child: Column(
            children: [
              for (final option in ExerciseType.values)
                RadioListTile<ExerciseType>(
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
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : FilledButton(onPressed: onSubmit, child: Text(submitLabel)),
        ),
      ],
    );
  }
}
