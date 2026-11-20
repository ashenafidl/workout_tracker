import "package:fl_chart/fl_chart.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";
import "package:phosphor_icons/phosphor_icons.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_config.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_result.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_sheet.dart";
import "package:workout_tracker/data/models/body_weight_entry.dart";
import "package:workout_tracker/data/models/stats.dart";
import "package:workout_tracker/ui/stats/view_models/body_weight_view_model.dart";
import "package:workout_tracker/ui/stats/view_models/stats_view_model.dart";
import "package:workout_tracker/utils/format_time.dart";

class StatsScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final StatsViewModel _viewModel = getIt<StatsViewModel>();
  late final BodyWeightViewModel _bodyWeightViewModel =
      getIt<BodyWeightViewModel>();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stats")),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.stats == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_viewModel.errorMessage != null && _viewModel.stats == null) {
            return _StatsError(
              message: _viewModel.errorMessage!,
              onRetry: _viewModel.refresh,
            );
          }
          final stats = _viewModel.stats;
          if (stats == null) {
            return const SizedBox.shrink();
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (_viewModel.errorMessage != null) ...[
                _StatsError(
                  message: _viewModel.errorMessage!,
                  onRetry: _viewModel.refresh,
                ),
                const SizedBox(height: 16),
              ],
              _MetricGrid(stats: stats),
              const SizedBox(height: 16),
              _BodyWeightSection(viewModel: _bodyWeightViewModel),
              const SizedBox(height: 16),
              _WeekdayDistribution(stats: stats),
            ],
          );
        },
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const new({required this.stats});

  final StatsSnapshot stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: _MetricCard(
                label: "Workouts",
                value: "${stats.totalWorkouts}",
                icon: PhosphorIconsDuotone.checkCircle,
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                label: "Total duration",
                value: _durationLabel(stats.totalDuration),
                icon: PhosphorIconsDuotone.timer,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const new({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const new({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PhosphorIcon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _WeekdayDistribution extends StatelessWidget {
  const new({required this.stats});

  final StatsSnapshot stats;

  static const _days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  @override
  Widget build(BuildContext context) {
    final maxCount = stats.workoutsByWeekday.fold<int>(
      0,
      (maximum, value) => value > maximum ? value : maximum,
    );
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final headerStyle = theme.textTheme.bodyMedium?.copyWith(
      color: cs.onSurfaceVariant,
      fontSize: 10,
    );
    final rowStyle = theme.textTheme.bodyMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return _SectionCard(
      title: "Workouts by day",
      icon: PhosphorIconsDuotone.calendarBlank,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Text("Day", style: headerStyle),
                const Spacer(),
                Text("Workouts", style: headerStyle),
              ],
            ),
          ),
          for (var index = 0; index < _days.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _WeekdayBar(
                label: _days[index],
                count: stats.workoutsByWeekday[index],
                fraction: maxCount == 0
                    ? 0
                    : stats.workoutsByWeekday[index] / maxCount,
                isTop:
                    maxCount > 0 && stats.workoutsByWeekday[index] == maxCount,
                style: rowStyle,
              ),
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Weekdays ${stats.weekdayWorkouts}  ·  Weekends ${stats.weekendWorkouts}",
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of the weekday chart: a rounded bar sized to [fraction] sits behind
/// the day label, with the count right-aligned across the full row width.
class _WeekdayBar extends StatelessWidget {
  const new({
    required this.label,
    required this.count,
    required this.fraction,
    required this.isTop,
    required this.style,
  });

  final String label;
  final int count;
  final double fraction;
  final bool isTop;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final barColor = cs.primary.withValues(alpha: isTop ? 0.32 : 0.14);

    return SizedBox(
      height: 30,
      child: Stack(
        alignment: .centerLeft,
        children: [
          if (fraction > 0)
            FractionallySizedBox(
              widthFactor: fraction,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: .circular(10),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(label, style: style),
                const Spacer(),
                Text("$count", style: style),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyWeightSection extends StatelessWidget {
  const new({required this.viewModel});

  final BodyWeightViewModel viewModel;

  Future<void> _inputWeight(
    BuildContext context, {
    BodyWeightEntry? entry,
  }) async {
    double? initialWeight = entry?.weightKg;
    if (entry == null) {
      try {
        initialWeight = (await viewModel.getLatest())?.weightKg;
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not load the latest weight: $error")),
        );
        return;
      }
    }
    if (!context.mounted) return;
    final result = await showModalBottomSheet<UnitInputResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => UnitInputSheet(
        title: entry == null ? "Log body weight" : "Edit body weight",
        config: DoubleInputConfig(
          initialValue: initialWeight ?? 0,
          label: "kg",
          min: 0.1,
        ),
      ),
    );
    if (result case DoubleInputResult(:final value)) {
      if (entry == null) {
        await viewModel.add(value);
      } else {
        await viewModel.update(entry.id, value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final theme = Theme.of(context);
        final entries = viewModel.filteredEntries;
        return _SectionCard(
          title: "Body weight",
          icon: PhosphorIconsDuotone.scales,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (viewModel.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (viewModel.errorMessage != null &&
                  viewModel.entries.isEmpty)
                Text(
                  "Weight entries could not be loaded: ${viewModel.errorMessage}",
                )
              else if (viewModel.entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text("Log your weight to start tracking progress."),
                )
              else ...[
                _BodyWeightSummary(viewModel: viewModel),
                const SizedBox(height: 16),
                SegmentedButton<WeightTimeRange>(
                  style: const ButtonStyle(
                    visualDensity: .compact,
                    tapTargetSize: .shrinkWrap,
                  ),
                  segments: [
                    for (final range in WeightTimeRange.values)
                      ButtonSegment<WeightTimeRange>(
                        value: range,
                        label: Text(_rangeLabel(range)),
                      ),
                  ],
                  selected: {viewModel.selectedRange},
                  onSelectionChanged: (selection) =>
                      viewModel.setRange(selection.first),
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 16),
                if (entries.isEmpty)
                  const SizedBox(
                    height: 160,
                    child: Center(child: Text("No entries in this period.")),
                  )
                else
                  _BodyWeightChart(entries: entries),
                if (viewModel.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Could not save the weight: ${viewModel.errorMessage}",
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 12),
                for (final entry in entries.reversed.take(3))
                  ListTile(
                    visualDensity: .compact,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text("${entry.weightKg.toStringAsFixed(1)} kg"),
                    subtitle: Text(DateFormat.yMMMd().format(entry.loggedAt)),
                    trailing: IconButton(
                      tooltip: "Edit weight",
                      icon: const PhosphorIcon(
                        PhosphorIconsDuotone.pencilSimple,
                        size: 20,
                      ),
                      onPressed: () => _inputWeight(context, entry: entry),
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _inputWeight(context),
                icon: const PhosphorIcon(PhosphorIconsDuotone.plus),
                label: const Text("Log weight"),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BodyWeightSummary extends StatelessWidget {
  const new({required this.viewModel});

  final BodyWeightViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final latest = viewModel.latest!;
    final change = viewModel.changeFromFirst!;
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        _WeightMetric(
          label: "Latest",
          value: "${latest.weightKg.toStringAsFixed(1)} kg",
        ),
        _WeightMetric(
          label: "Change",
          value: "${change > 0 ? "+" : ""}${change.toStringAsFixed(1)} kg",
        ),
        _WeightMetric(
          label: "Range",
          value:
              "${viewModel.lowest!.weightKg.toStringAsFixed(1)}–${viewModel.highest!.weightKg.toStringAsFixed(1)} kg",
        ),
      ],
    );
  }
}

class _WeightMetric extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _BodyWeightChart extends StatelessWidget {
  const new({required this.entries});

  final List<BodyWeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weights = entries.map((entry) => entry.weightKg);
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final padding = maxWeight == minWeight
        ? 0.5
        : (maxWeight - minWeight) * 0.15;
    final chartEntries = entries.length == 1
        ? [...entries, entries.single]
        : entries;
    final spots = [
      for (var index = 0; index < chartEntries.length; index++)
        FlSpot(index.toDouble(), chartEntries[index].weightKg),
    ];

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (spots.length - 1).toDouble(),
              minY: minWeight - padding,
              maxY: maxWeight + padding,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.colorScheme.outlineVariant,
                  strokeWidth: 1,
                ),
              ),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => [
                    for (final spot in spots)
                      LineTooltipItem(
                        "${DateFormat.MMMd().format(chartEntries[spot.x.round()].loggedAt)}\n${spot.y.toStringAsFixed(1)} kg",
                        TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: theme.colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                          radius: 2.5,
                          color: theme.colorScheme.primary,
                          strokeWidth: 0,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.35),
                        theme.colorScheme.primary.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat.MMMd().format(entries.first.loggedAt)),
            Text(DateFormat.MMMd().format(entries.last.loggedAt)),
          ],
        ),
      ],
    );
  }
}

String _rangeLabel(WeightTimeRange range) {
  return switch (range) {
    WeightTimeRange.month1 => "1M",
    WeightTimeRange.month3 => "3M",
    WeightTimeRange.month6 => "6M",
    WeightTimeRange.yearAll => "All",
  };
}

class _StatsError extends StatelessWidget {
  const new({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Stats could not be loaded or refreshed."),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text("Retry")),
          ],
        ),
      ),
    );
  }
}

String _durationLabel(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours == 0) return formatDuration(duration);
  return minutes == 0 ? "${hours}h" : "${hours}h ${minutes}m";
}
