import "package:flutter/material.dart";
import "package:workout_tracker/data/models/exercises.dart";

class ExerciseSideBadge extends StatelessWidget {
  const new({super.key, required this.side});

  final ExerciseSide side;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: .circular(4),
      ),
      child: Text(
        side.shortLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class BilateralMarker extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: .circular(4),
      ),
      child: Icon(
        Icons.swap_horiz,
        size: 12,
        color: colorScheme.onSecondaryContainer,
      ),
    );
  }
}

class ExerciseTitleWithSide extends StatelessWidget {
  const new({super.key, required this.name, this.side, this.style});

  final String name;
  final ExerciseSide? side;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        Flexible(
          child: Text(name, style: style, overflow: TextOverflow.ellipsis),
        ),
        if (side != null) ExerciseSideBadge(side: side!),
      ],
    );
  }
}
