import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/data/models/stats.dart";
import "package:workout_tracker/ui/stats/view_models/stats_view_model.dart";
import "package:workout_tracker/utils/format_time.dart";

class StatsScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final StatsViewModel _viewModel = getIt<StatsViewModel>();

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
                icon: Icons.check_circle_outline,
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                label: "Circuits",
                value: "${stats.totalCircuits}",
                icon: Icons.loop,
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                label: "Reps",
                value: _numberLabel(stats.totalReps),
                icon: Icons.repeat,
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                label: "Total duration",
                value: _durationLabel(stats.totalDuration),
                icon: Icons.timer_outlined,
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
            Icon(icon, color: theme.colorScheme.primary),
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
                Icon(icon, size: 20, color: theme.colorScheme.primary),
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
    return _SectionCard(
      title: "Workouts by day",
      icon: Icons.calendar_month_outlined,
      child: Column(
        children: [
          for (var index = 0; index < _days.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(width: 34, child: Text(_days[index])),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: maxCount == 0
                          ? 0
                          : stats.workoutsByWeekday[index] / maxCount,
                      minHeight: 10,
                      borderRadius: .circular(5),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      "${stats.workoutsByWeekday[index]}",
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Weekdays ${stats.weekdayWorkouts}  ·  Weekends ${stats.weekendWorkouts}",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
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

String _numberLabel(int value) {
  return NumberFormat.compact().format(value);
}

String _durationLabel(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours == 0) return formatDuration(duration);
  return minutes == 0 ? "${hours}h" : "${hours}h ${minutes}m";
}
