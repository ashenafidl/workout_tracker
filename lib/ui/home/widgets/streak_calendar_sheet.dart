import "dart:math" as math;

import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";
import "package:workout_tracker/data/models/daily_activity.dart";
import "package:workout_tracker/utils/format_time.dart";

class StreakCalendarSheet extends StatefulWidget {
  const new({
    super.key,
    required this.currentStreak,
    required this.isStreakCountedToday,
    required this.dailyActivityStream,
  });

  final int currentStreak;
  final bool isStreakCountedToday;
  final Stream<List<DailyActivity>> dailyActivityStream;

  @override
  State<StreakCalendarSheet> createState() => _StreakCalendarSheetState();
}

class _StreakCalendarSheetState extends State<StreakCalendarSheet> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;
  Map<DateTime, DailyActivity> _activityByDate = {};

  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = _currentMonth;
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _changeMonth(int offset) {
    final nextMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + offset,
    );
    if (nextMonth.isAfter(_currentMonth)) return;
    setState(() {
      _visibleMonth = nextMonth;
      if (_selectedDate.year != nextMonth.year ||
          _selectedDate.month != nextMonth.month) {
        _selectedDate = DateTime(nextMonth.year, nextMonth.month, 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final streakColor = widget.isStreakCountedToday
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              Icons.local_fire_department_rounded,
              color: streakColor,
              size: 36,
            ),
            const SizedBox(height: 4),
            Text(
              "${widget.currentStreak} day streak",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: widget.isStreakCountedToday
                    ? null
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              "Keep showing up",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<DailyActivity>>(
              stream: widget.dailyActivityStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    "Could not load workout activity: ${snapshot.error}",
                    textAlign: TextAlign.center,
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  );
                }

                _activityByDate = {
                  for (final activity in snapshot.data!)
                    DateTime(
                      activity.date.year,
                      activity.date.month,
                      activity.date.day,
                    ): activity,
                };

                return _buildCalendar(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canGoForward = _visibleMonth.isBefore(_currentMonth);
    final selectedActivity = _activityByDate[_selectedDate];
    final selectedWorkoutDuration =
        selectedActivity?.workoutDuration ?? Duration.zero;
    final selectedRestDuration =
        selectedActivity?.restDuration ?? Duration.zero;
    final hasSelectedActivity =
        selectedActivity != null &&
        (selectedWorkoutDuration > Duration.zero ||
            selectedRestDuration > Duration.zero);

    // High contrast ring colors
    final workoutColor = colorScheme.primary;
    final restColor = colorScheme.secondary;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: "Previous month",
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
            Expanded(
              child: Text(
                _visibleMonth.year == DateTime.now().year
                    ? DateFormat.MMMM().format(_visibleMonth)
                    : DateFormat("MMMM y").format(_visibleMonth),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: "Next month",
              onPressed: canGoForward ? () => _changeMonth(1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity;
            if (velocity == null || velocity.abs() < 100) return;
            _changeMonth(velocity > 0 ? -1 : 1);
          },
          child: _buildGrid(_activityByDate, _visibleMonth),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _LegendItem(color: workoutColor, label: "Workout"),
                  const SizedBox(width: 16),
                  _LegendItem(color: restColor, label: "Rest"),
                ],
              ),
              Text(
                hasSelectedActivity
                    ? "${formatDuration(selectedWorkoutDuration)} workout, ${formatDuration(selectedRestDuration)} rest"
                    : "No activity",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(
    Map<DateTime, DailyActivity> activityByDate,
    DateTime month,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final today = DateTime.now();
    final isCurrentMonth =
        month.year == today.year && month.month == today.month;
    final dayCount = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlankCount = DateTime(month.year, month.month, 1).weekday - 1;

    final trackColor = colorScheme.onSurface.withValues(alpha: 0.15);
    final workoutColor = colorScheme.primary;
    final restColor = colorScheme.secondary;

    return Column(
      children: [
        Row(
          children: [
            for (var weekday = 1; weekday <= 7; weekday++)
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat.E().format(DateTime(2024, 1, weekday)),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          itemCount: leadingBlankCount + dayCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 46,
          ),
          itemBuilder: (context, index) {
            final day = index - leadingBlankCount + 1;
            if (day < 1 || day > dayCount) return const SizedBox.shrink();

            final date = DateTime(month.year, month.month, day);
            final isFuture = isCurrentMonth && day > today.day;
            final isSelected =
                _selectedDate.year == date.year &&
                _selectedDate.month == date.month &&
                _selectedDate.day == date.day;

            return _DayCell(
              day: day,
              date: date,
              activity: activityByDate[date],
              isFuture: isFuture,
              isSelected: isSelected,
              workoutColor: workoutColor,
              restColor: restColor,
              trackColor: trackColor,
              onTap: isFuture
                  ? null
                  : () => setState(() => _selectedDate = date),
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const new({
    required this.day,
    required this.date,
    required this.activity,
    required this.isFuture,
    required this.isSelected,
    required this.workoutColor,
    required this.restColor,
    required this.trackColor,
    required this.onTap,
  });

  final int day;
  final DateTime date;
  final DailyActivity? activity;
  final bool isFuture;
  final bool isSelected;
  final Color workoutColor;
  final Color restColor;
  final Color trackColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final workoutDuration = activity?.workoutDuration ?? Duration.zero;
    final restDuration = activity?.restDuration ?? Duration.zero;
    final totalDuration = workoutDuration + restDuration;
    final workoutFraction = totalDuration == Duration.zero
        ? 0.0
        : workoutDuration.inMicroseconds / totalDuration.inMicroseconds;
    final formattedDate = DateFormat.yMMMMd().format(date);
    final description = isFuture
        ? "Day $day, upcoming"
        : activity == null
        ? "$formattedDate, no workout"
        : "$formattedDate: workout ${formatDuration(workoutDuration)}, rest ${formatDuration(restDuration)}";

    return Semantics(
      label: description,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: isSelected
                    ? Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.35),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Center(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: Opacity(
                    opacity: isFuture ? 0.3 : 1.0,
                    child: CustomPaint(
                      painter: _ActivityRingPainter(
                        workoutFraction: workoutFraction,
                        hasActivity: totalDuration > Duration.zero,
                        workoutColor: workoutColor,
                        restColor: restColor,
                        trackColor: trackColor,
                      ),
                      child: Center(
                        child: Text(
                          "$day",
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isFuture
                                ? colorScheme.onSurfaceVariant
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityRingPainter extends CustomPainter {
  const new({
    required this.workoutFraction,
    required this.hasActivity,
    required this.workoutColor,
    required this.restColor,
    required this.trackColor,
  });

  final double workoutFraction;
  final bool hasActivity;
  final Color workoutColor;
  final Color restColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const strokeWidth = 3.5;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -math.pi / 2,
      math.pi * 2,
      false,
      trackPaint,
    );

    if (!hasActivity) return;

    final workoutSweep = math.pi * 2 * workoutFraction;
    final restSweep = math.pi * 2 - workoutSweep;
    final ringRect = rect.deflate(strokeWidth / 2);

    final workoutPaint = Paint()
      ..color = workoutColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final restPaint = Paint()
      ..color = restColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    if (workoutSweep > 0) {
      canvas.drawArc(ringRect, -math.pi / 2, workoutSweep, false, workoutPaint);
    }
    if (restSweep > 0) {
      canvas.drawArc(
        ringRect,
        -math.pi / 2 + workoutSweep,
        restSweep,
        false,
        restPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ActivityRingPainter oldDelegate) {
    return workoutFraction != oldDelegate.workoutFraction ||
        hasActivity != oldDelegate.hasActivity ||
        workoutColor != oldDelegate.workoutColor ||
        restColor != oldDelegate.restColor ||
        trackColor != oldDelegate.trackColor;
  }
}

class _LegendItem extends StatelessWidget {
  const new({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
