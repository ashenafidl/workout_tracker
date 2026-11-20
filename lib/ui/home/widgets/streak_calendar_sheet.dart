import "dart:math" as math;

import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";
import "package:phosphor_icons/phosphor_icons.dart";
import "package:workout_tracker/data/models/daily_activity.dart";
import "package:workout_tracker/data/models/workout_schedule.dart";
import "package:workout_tracker/utils/format_time.dart";

class StreakCalendarSheet extends StatefulWidget {
  const new({
    super.key,
    required this.currentStreak,
    required this.isStreakCountedToday,
    required this.dailyActivityStream,
    required this.scheduleStream,
    this.now = DateTime.now,
  });

  final int currentStreak;
  final bool isStreakCountedToday;
  final Stream<List<DailyActivity>> dailyActivityStream;
  final Stream<WorkoutSchedule> scheduleStream;

  /// Clock used to resolve "today"; overridable in tests.
  final DateTime Function() now;

  @override
  State<StreakCalendarSheet> createState() => _StreakCalendarSheetState();
}

class _StreakCalendarSheetState extends State<StreakCalendarSheet> {
  static const Duration _monthTransitionDuration = Duration(milliseconds: 280);
  static const double _rowHeight = 46;

  /// Earliest month the pager can reach.
  static final DateTime _firstMonth = DateTime(2000);

  late DateTime _visibleMonth;
  late DateTime _selectedDate;
  late final PageController _pageController;
  Map<DateTime, DailyActivity> _activityByDate = {};
  DateTime? _firstActivityDate;

  DateTime get _today {
    final now = widget.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _currentMonth {
    final now = widget.now();
    return DateTime(now.year, now.month);
  }

  int _pageFor(DateTime month) =>
      (month.year - _firstMonth.year) * 12 + month.month - _firstMonth.month;

  DateTime _monthFor(int page) =>
      DateTime(_firstMonth.year, _firstMonth.month + page);

  @override
  void initState() {
    super.initState();
    _visibleMonth = _currentMonth;
    _selectedDate = _today;
    _pageController = PageController(initialPage: _pageFor(_visibleMonth));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Called as soon as a page becomes the nearest one (midway through a drag,
  /// or immediately for chevron taps), so the header tracks the gesture.
  void _showMonth(DateTime month) {
    if (month == _visibleMonth) return;
    setState(() {
      _visibleMonth = month;
      if (_selectedDate.year != month.year ||
          _selectedDate.month != month.month) {
        _selectedDate = DateTime(month.year, month.month, 1);
      }
    });
  }

  void _changeMonth(int offset) {
    // Ignore chevron taps while the pager is between pages (drag or running
    // animation) so the header and grid never drift out of sync.
    final page = _pageController.hasClients ? _pageController.page : null;
    if (page == null || page != page.roundToDouble()) return;
    final target = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
    if (target.isAfter(_currentMonth) || target.isBefore(_firstMonth)) return;
    _showMonth(target);
    _pageController.animateToPage(
      _pageFor(target),
      duration: _monthTransitionDuration,
      curve: Curves.easeInOut,
    );
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
            PhosphorIcon(
              PhosphorIconsDuotone.fire,
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
              builder: (context, activitySnapshot) {
                return StreamBuilder<WorkoutSchedule>(
                  stream: widget.scheduleStream,
                  builder: (context, scheduleSnapshot) {
                    final error =
                        activitySnapshot.error ?? scheduleSnapshot.error;
                    if (error != null) {
                      return Text(
                        "Could not load workout activity: $error",
                        textAlign: TextAlign.center,
                      );
                    }
                    if (!activitySnapshot.hasData ||
                        !scheduleSnapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      );
                    }

                    _activityByDate = {
                      for (final activity in activitySnapshot.data!)
                        DateTime(
                          activity.date.year,
                          activity.date.month,
                          activity.date.day,
                        ): activity,
                    };
                    _firstActivityDate = _activityByDate.keys.fold<DateTime?>(
                      null,
                      (earliest, date) =>
                          earliest == null || date.isBefore(earliest)
                          ? date
                          : earliest,
                    );

                    return _buildCalendar(context, scheduleSnapshot.data!);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, WorkoutSchedule schedule) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = _CalendarColors.of(colorScheme);
    final today = _today;
    final canGoForward = _visibleMonth.isBefore(_currentMonth);
    final selectedActivity = _activityByDate[_selectedDate];
    final selectedWorkoutDuration =
        selectedActivity?.workoutDuration ?? Duration.zero;
    final selectedRestDuration =
        selectedActivity?.restDuration ?? Duration.zero;
    final selectedStatus = _dayStatusFor(
      date: _selectedDate,
      today: today,
      activity: selectedActivity,
      schedule: schedule,
      firstActivityDate: _firstActivityDate,
    );
    final summaryStyle = theme.textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w500,
      fontSize: 10,
    );
    final selectedSummary = switch (selectedStatus) {
      _DayStatus.active => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ColorLabel(
            color: colors.workout,
            label: "${formatDuration(selectedWorkoutDuration)} workout",
            style: summaryStyle,
          ),
          const SizedBox(width: 12),
          _ColorLabel(
            color: colors.restTime,
            label: "${formatDuration(selectedRestDuration)} rest",
            style: summaryStyle,
          ),
        ],
      ),
      _DayStatus.restDay => Text("Rest day", style: summaryStyle),
      _DayStatus.missed => Text("Missed", style: summaryStyle),
      _DayStatus.future ||
      _DayStatus.noActivity => Text("No activity", style: summaryStyle),
    };

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: "Previous month",
              onPressed: () => _changeMonth(-1),
              icon: const PhosphorIcon(PhosphorIconsDuotone.caretLeft),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
            Expanded(
              child: Text(
                _visibleMonth.year == today.year
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
              icon: const PhosphorIcon(PhosphorIconsDuotone.caretRight),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 4),
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
        _buildGridViewport(schedule, colors, today),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Center(child: selectedSummary),
        ),
      ],
    );
  }

  /// Clipped pager for the date grid, as tall as the visible month's week
  /// rows. It follows the finger during a drag (back and forth), snaps or
  /// flings on release, and is driven by the chevrons too.
  Widget _buildGridViewport(
    WorkoutSchedule schedule,
    _CalendarColors colors,
    DateTime today,
  ) {
    return SizedBox(
      width: double.infinity,
      // Sized to the visible month, so 4/5/6-row months change the height.
      height: _rowHeight * _weekRowsIn(_visibleMonth),
      child: PageView.builder(
        controller: _pageController,
        // Pages end at the current month, so future months are unreachable.
        itemCount: _pageFor(_currentMonth) + 1,
        onPageChanged: (page) => _showMonth(_monthFor(page)),
        itemBuilder: (context, page) {
          final month = _monthFor(page);
          // A neighbouring month can have more rows than the visible one
          // while dragging; let it overflow downward (the pager clips it).
          return OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: double.infinity,
            child: _MonthGrid(
              key: ValueKey<DateTime>(month),
              month: month,
              today: today,
              selectedDate: _selectedDate,
              activityByDate: _activityByDate,
              firstActivityDate: _firstActivityDate,
              schedule: schedule,
              colors: colors,
              rowHeight: _rowHeight,
              onDateSelected: (date) => setState(() => _selectedDate = date),
            ),
          );
        },
      ),
    );
  }
}

int _daysIn(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

int _leadingBlanksIn(DateTime month) =>
    DateTime(month.year, month.month, 1).weekday - 1;

int _weekRowsIn(DateTime month) =>
    ((_leadingBlanksIn(month) + _daysIn(month)) / 7).ceil();

enum _DayStatus { future, active, restDay, missed, noActivity }

_DayStatus _dayStatusFor({
  required DateTime date,
  required DateTime today,
  required DailyActivity? activity,
  required WorkoutSchedule schedule,
  required DateTime? firstActivityDate,
}) {
  if (date.isAfter(today)) return _DayStatus.future;
  if (activity != null) return _DayStatus.active;
  if (!schedule.isScheduled(date)) return _DayStatus.restDay;
  // Only past scheduled days after the first logged workout count as missed;
  // today is still open, and days before the user started are not failures.
  if (date.isBefore(today) &&
      firstActivityDate != null &&
      !date.isBefore(firstActivityDate)) {
    return _DayStatus.missed;
  }
  return _DayStatus.noActivity;
}

class _CalendarColors {
  const new({
    required this.workout,
    required this.restTime,
    required this.restDay,
    required this.missed,
    required this.track,
  });

  factory of(ColorScheme colorScheme) => _CalendarColors(
    workout: colorScheme.primary,
    restTime: colorScheme.tertiary,
    restDay: colorScheme.onSurfaceVariant,
    missed: colorScheme.outline,
    track: colorScheme.outline,
  );

  final Color workout;
  final Color restTime;
  final Color restDay;
  final Color missed;
  final Color track;
}

class _MonthGrid extends StatelessWidget {
  const new({
    super.key,
    required this.month,
    required this.today,
    required this.selectedDate,
    required this.activityByDate,
    required this.firstActivityDate,
    required this.schedule,
    required this.colors,
    required this.rowHeight,
    required this.onDateSelected,
  });

  final DateTime month;
  final DateTime today;
  final DateTime selectedDate;
  final Map<DateTime, DailyActivity> activityByDate;
  final DateTime? firstActivityDate;
  final WorkoutSchedule schedule;
  final _CalendarColors colors;
  final double rowHeight;
  final ValueChanged<DateTime>? onDateSelected;

  @override
  Widget build(BuildContext context) {
    final leadingBlankCount = _leadingBlanksIn(month);
    final dayCount = _daysIn(month);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < _weekRowsIn(month); row++)
          SizedBox(
            height: rowHeight,
            child: Row(
              children: [
                for (var column = 0; column < 7; column++)
                  Expanded(
                    child: _buildCell(
                      row * 7 + column - leadingBlankCount + 1,
                      dayCount,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCell(int day, int dayCount) {
    if (day < 1 || day > dayCount) return const SizedBox.shrink();

    final date = DateTime(month.year, month.month, day);
    final activity = activityByDate[date];
    final status = _dayStatusFor(
      date: date,
      today: today,
      activity: activity,
      schedule: schedule,
      firstActivityDate: firstActivityDate,
    );
    final onDateSelected = this.onDateSelected;
    return _DayCell(
      day: day,
      date: date,
      activity: activity,
      status: status,
      isSelected: selectedDate == date,
      colors: colors,
      onTap: status == _DayStatus.future || onDateSelected == null
          ? null
          : () => onDateSelected(date),
    );
  }
}

class _DayCell extends StatelessWidget {
  const new({
    required this.day,
    required this.date,
    required this.activity,
    required this.status,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final int day;
  final DateTime date;
  final DailyActivity? activity;
  final _DayStatus status;
  final bool isSelected;
  final _CalendarColors colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFuture = status == _DayStatus.future;
    final workoutDuration = activity?.workoutDuration ?? Duration.zero;
    final restDuration = activity?.restDuration ?? Duration.zero;
    final totalDuration = workoutDuration + restDuration;
    final workoutFraction = totalDuration == Duration.zero
        ? 0.0
        : workoutDuration.inMicroseconds / totalDuration.inMicroseconds;
    final formattedDate = DateFormat.yMMMMd().format(date);
    final description = switch (status) {
      _DayStatus.future => "Day $day, upcoming",
      _DayStatus.active =>
        "$formattedDate: workout ${formatDuration(workoutDuration)}, rest ${formatDuration(restDuration)}",
      _DayStatus.restDay => "$formattedDate, rest day",
      _DayStatus.missed => "$formattedDate, missed workout",
      _DayStatus.noActivity => "$formattedDate, no workout",
    };
    final (trackColor, dashedTrack) = switch (status) {
      _DayStatus.restDay => (colors.restDay, true),
      _DayStatus.missed => (colors.missed, false),
      _DayStatus.future ||
      _DayStatus.active ||
      _DayStatus.noActivity => (colors.track, false),
    };

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
                        workoutColor: colors.workout,
                        restColor: colors.restTime,
                        trackColor: trackColor,
                        dashedTrack: dashedTrack,
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
    required this.dashedTrack,
  });

  static const int _dashCount = 12;

  final double workoutFraction;
  final bool hasActivity;
  final Color workoutColor;
  final Color restColor;
  final Color trackColor;
  final bool dashedTrack;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const strokeWidth = 3.5;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (dashedTrack) {
      const segment = math.pi * 2 / _dashCount;
      for (var index = 0; index < _dashCount; index++) {
        canvas.drawArc(
          rect.deflate(strokeWidth / 2),
          -math.pi / 2 + segment * index,
          segment * 0.5,
          false,
          trackPaint,
        );
      }
    } else {
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        -math.pi / 2,
        math.pi * 2,
        false,
        trackPaint,
      );
    }

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
        trackColor != oldDelegate.trackColor ||
        dashedTrack != oldDelegate.dashedTrack;
  }
}

class _ColorLabel extends StatelessWidget {
  const new({required this.color, required this.label, required this.style});

  final Color color;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }
}
