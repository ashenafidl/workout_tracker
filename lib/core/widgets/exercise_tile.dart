import "package:material_ui/material_ui.dart";
import "package:workout_tracker/core/widgets/exercise_side_badge.dart";
import "package:workout_tracker/data/models/exercises.dart";

class ExerciseTile extends StatelessWidget {
  const new({super.key, required this.exerciseWithTypes, required this.onTap});

  final ExerciseWithTypes exerciseWithTypes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(exerciseWithTypes.exercise.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exerciseWithTypes.exercise.description != null)
            Text(
              exerciseWithTypes.exercise.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Wrap(
            spacing: 6,
            children: [
              for (final type in exerciseWithTypes.supportedTypes)
                Icon(
                  type.icon,
                  size: 12,
                  color: Theme.of(context).disabledColor,
                ),
            ],
          ),
        ],
      ),
      trailing: exerciseWithTypes.exercise.isBilateral
          ? const BilateralMarker()
          : null,
      onTap: onTap,
    );
  }
}
