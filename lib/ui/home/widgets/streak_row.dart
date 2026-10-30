import "package:material_ui/material_ui.dart";

class StreakRow extends StatelessWidget {
  const new({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.isStreakCountedToday,
    required this.onTap,
  });

  final int currentStreak;
  final int longestStreak;
  final bool isStreakCountedToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPersonalBest = currentStreak > 0 && currentStreak >= longestStreak;
    final streakColor = isStreakCountedToday
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.local_fire_department_rounded, color: streakColor),
                const SizedBox(width: 8),
                Text(
                  "$currentStreak day streak",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isStreakCountedToday
                        ? null
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isPersonalBest) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      "PB",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (!isPersonalBest) ...[
                  const SizedBox(width: 8),
                  Text(
                    "Best: $longestStreak days",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
