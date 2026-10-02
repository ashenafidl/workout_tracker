import "dart:async";

import "package:flutter/material.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/core/widgets/exercise_side_badge.dart";
import "package:workout_tracker/data/models/challenge.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/services/sound_service.dart";
import "package:workout_tracker/ui/programs/view_models/challenge_view_model.dart";
import "package:workout_tracker/utils/format_time.dart";

class ChallengeScreen extends StatefulWidget {
  const new({
    super.key,
    required this.workoutWithExercises,
    required this.programId,
  });

  final WorkoutWithExercises workoutWithExercises;
  final int programId;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  late final ChallengeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<ChallengeViewModel>(
      param1: widget.workoutWithExercises,
      param2: widget.programId,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.workoutWithExercises.workout.name)),
          body: _buildBody(),
          bottomNavigationBar: _buildBottomBar(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_viewModel.progress.isEmpty) {
      return const Center(child: Text("No exercises in this challenge"));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _viewModel.progress.length,
      itemBuilder: (context, index) {
        final item = _viewModel.progress[index];
        return _ChallengeExerciseCard(
          key: ValueKey("challenge_${item.workoutExerciseId}_${item.side}"),
          item: item,
          viewModel: _viewModel,
          onLogReps: () => _openLogSheet(item),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: FilledButton(
            onPressed: _viewModel.allTargetsMet || !_viewModel.isCompleted
                ? _markDone
                : null,
            child: const Text("Mark as done for today"),
          ),
        ),
      ),
    );
  }

  Future<void> _markDone() async {
    await _viewModel.markDone();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _openLogSheet(ChallengeExerciseProgress item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) =>
          _LogEntrySheet(item: item, viewModel: _viewModel),
    );
  }
}

class _ChallengeExerciseCard extends StatefulWidget {
  const new({
    super.key,
    required this.item,
    required this.viewModel,
    required this.onLogReps,
  });

  final ChallengeExerciseProgress item;
  final ChallengeViewModel viewModel;
  final VoidCallback onLogReps;

  @override
  State<_ChallengeExerciseCard> createState() => _ChallengeExerciseCardState();
}

class _ChallengeExerciseCardState extends State<_ChallengeExerciseCard> {
  static const Duration _tick = Duration(milliseconds: 100);

  final SoundService _soundService = getIt<SoundService>();

  Timer? _ticker;
  Duration _runDuration = Duration.zero;
  bool _isRunning = false;

  /// Optimistically tracked total, so the bar does not dip while a just-logged
  /// entry is still traveling through the database stream.
  int _localAccumulated = 0;

  bool get _isDuration => widget.item.exercise.type == ExerciseType.duration;

  int get _accumulatedSeconds =>
      widget.item.accumulatedDurationSeconds > _localAccumulated
      ? widget.item.accumulatedDurationSeconds
      : _localAccumulated;

  @override
  void dispose() {
    _ticker?.cancel();
    if (_isRunning && _runDuration.inSeconds > 0) {
      unawaited(widget.viewModel.logEntry(widget.item, _runDuration.inSeconds));
    }
    super.dispose();
  }

  double get _durationProgress {
    final target = widget.item.targetDurationSeconds ?? 0;
    if (target <= 0) return 0;

    final totalSeconds =
        _accumulatedSeconds + _runDuration.inMilliseconds / 1000;
    return (totalSeconds / target).clamp(0.0, 1.0);
  }

  void _toggle() {
    if (_isRunning) {
      unawaited(_pauseAndLog());
    } else {
      _start();
    }
  }

  void _start() {
    if (widget.item.isComplete) return;

    setState(() => _isRunning = true);
    _ticker = Timer.periodic(_tick, (_) {
      if (!mounted) return;

      setState(() => _runDuration += _tick);

      final target = widget.item.targetDurationSeconds ?? 0;
      final totalSeconds = _accumulatedSeconds + _runDuration.inSeconds;
      if (target > 0 && totalSeconds >= target) {
        unawaited(_pauseAndLog(completed: true));
      }
    });
  }

  /// Stops the stopwatch and logs whatever was accumulated. Pausing (or
  /// reaching the target) is what commits the entry.
  Future<void> _pauseAndLog({bool completed = false}) async {
    _ticker?.cancel();
    _ticker = null;

    if (completed) {
      unawaited(_soundService.playExerciseComplete());
    }

    final seconds = _runDuration.inSeconds;
    setState(() {
      _isRunning = false;
      _runDuration = Duration.zero;
      _localAccumulated = _accumulatedSeconds + seconds;
    });

    if (seconds > 0) {
      await widget.viewModel.logEntry(widget.item, seconds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _isDuration
        ? _durationProgress
        : widget.item.progressFraction;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ExerciseTitleWithSide(
                    name: widget.item.exercise.name,
                    side: widget.item.side,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (widget.item.isComplete)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: .circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _progressLabel(),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                _buildAction(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction() {
    if (!_isDuration) {
      return OutlinedButton(
        onPressed: widget.onLogReps,
        style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
        child: const Text("+ Log"),
      );
    }

    final canRun = _isRunning || !widget.item.isComplete;
    return IconButton.filledTonal(
      onPressed: canRun ? _toggle : null,
      tooltip: _isRunning ? "Pause and log" : "Start",
      icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
    );
  }

  String _progressLabel() {
    final targetReps = widget.item.targetReps;
    if (targetReps != null) {
      return "${widget.item.accumulatedReps} / $targetReps reps";
    }

    final targetDuration = widget.item.targetDurationSeconds ?? 0;
    final accumulated = _accumulatedSeconds + _runDuration.inSeconds;
    return "${formatDuration(Duration(seconds: accumulated))}"
        " / ${formatDuration(Duration(seconds: targetDuration))}";
  }
}

class _LogEntrySheet extends StatefulWidget {
  const new({required this.item, required this.viewModel});

  final ChallengeExerciseProgress item;
  final ChallengeViewModel viewModel;

  @override
  State<_LogEntrySheet> createState() => _LogEntrySheetState();
}

class _LogEntrySheetState extends State<_LogEntrySheet> {
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _log(int value) async {
    if (value <= 0) return;

    await widget.viewModel.logEntry(widget.item, value);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _logTypedReps() async {
    final value = int.tryParse(_valueController.text.trim()) ?? 0;
    await _log(value);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ExerciseTitleWithSide(
              name: widget.item.exercise.name,
              side: widget.item.side,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final amount in const [5, 10, 20, 50])
                ActionChip(
                  label: Text("+$amount"),
                  onPressed: () => _log(amount),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Custom reps"),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _logTypedReps,
              child: const Text("Log"),
            ),
          ),
        ],
      ),
    );
  }
}
