import "package:flutter/material.dart";
import "package:workout_tracker/ui/more/widgets/more_tile.dart";

class MoreTileGroup extends StatelessWidget {
  const MoreTileGroup({super.key, required this.title, required this.children});

  final String title;
  final List<MoreTile> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            // ← replaced ListView with Column to avoid unbounded height
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: .5,
                    indent: 16,
                    endIndent: 16,
                    color: Theme.of(context).dividerColor.withAlpha(25),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
