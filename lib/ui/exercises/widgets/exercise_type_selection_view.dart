import "package:material_ui/material_ui.dart";
import "package:workout_tracker/data/models/exercises.dart";

class ExerciseTypeSelectionView extends StatelessWidget {
  const new({
    super.key,
    required this.name,
    required this.description,
    required this.selectedTypes,
    required this.isBilateral,
    required this.onBilateralChanged,
    required this.isLoading,
    required this.submitLabel,
    required this.onBack,
    required this.onTypeToggled,
    this.errorMessage,
    required this.onSubmit,
  });

  final String name;
  final String description;
  final Set<ExerciseType> selectedTypes;
  final bool isBilateral;
  final ValueChanged<bool> onBilateralChanged;
  final bool isLoading;
  final String submitLabel;
  final VoidCallback onBack;
  final ValueChanged<ExerciseType> onTypeToggled;
  final String? errorMessage;
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in ExerciseType.values)
              FilterChip(
                avatar: Icon(option.icon, size: 18),
                label: Text(option.name),
                selected: selectedTypes.contains(option),
                onSelected: isLoading ? null : (_) => onTypeToggled(option),
                showCheckmark: false,
              ),
          ],
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ] else if (selectedTypes.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            "Select at least one exercise type",
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const Divider(),
        const SizedBox(height: 8),
        SwitchListTile(
          value: isBilateral,
          onChanged: isLoading ? null : onBilateralChanged,
          title: const Text("Bilateral"),
          subtitle: const Text(
            "Performed on both sides, e.g. curls or lunges. Lets you pick a side when adding it to a workout.",
          ),
          secondary: const Icon(Icons.swap_horiz),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : FilledButton(
                  onPressed: selectedTypes.isEmpty ? null : onSubmit,
                  child: Text(submitLabel),
                ),
        ),
      ],
    );
  }
}
