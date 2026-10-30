import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:wakelock_plus/wakelock_plus.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/data/models/workout.dart";
import "package:workout_tracker/database/database.dart";
import "package:workout_tracker/ui/session/view_models/workout_session_view_model.dart";
import "package:workout_tracker/ui/session/widgets/completed_view.dart";
import "package:workout_tracker/ui/session/widgets/countdown_view.dart";
import "package:workout_tracker/ui/session/widgets/rest_view.dart";
import "package:workout_tracker/ui/session/widgets/session_bottom_panel.dart";
import "package:workout_tracker/ui/session/widgets/session_progress_bar.dart";

enum _SessionExitAction { keepGoing, quit, recordProgress }

class WorkoutSessionScreen extends StatefulWidget {
  const new({super.key, required this.args});

  final WorkoutSessionArgs args;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late final WorkoutSessionViewModel vm;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    vm = getIt<WorkoutSessionViewModel>(
      param1: WorkoutSessionArgs(
        workoutWithExercises: widget.args.workoutWithExercises,
        programId: widget.args.programId,
        workoutIndex: widget.args.workoutWithExercises.workout.position,
        totalWorkoutsInProgram: widget.args.totalWorkoutsInProgram,
      ),
      param2: getIt<AppDatabase>(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => vm.startCountDown());
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    vm.dispose();
    super.dispose();
  }

  Future<_SessionExitAction?> _onWillPop() async {
    if (vm.phase == SessionPhase.completed) return _SessionExitAction.quit;

    var keepProgress = false;
    return showDialog<_SessionExitAction>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return Dialog(
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.help_outline_rounded,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Quit workout?",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vm.hasCompletedProgress
                        ? "You can keep your completed work and view your session summary."
                        : "You haven't completed any exercises to save yet.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (vm.hasCompletedProgress) ...[
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        "Keep my progress",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: keepProgress,
                      onChanged: (value) {
                        setDialogState(() {
                          keepProgress = value ?? false;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(
                            dialogContext,
                            keepProgress
                                ? _SessionExitAction.recordProgress
                                : _SessionExitAction.quit,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            "Quit",
                            style: TextStyle(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(
                            dialogContext,
                            _SessionExitAction.keepGoing,
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Keep going",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final action = await _onWillPop();
        if (!context.mounted) return;
        switch (action) {
          case _SessionExitAction.quit:
            context.pop();
            break;
          case _SessionExitAction.recordProgress:
            await vm.recordPartialProgress();
            break;
          case _SessionExitAction.keepGoing:
          case null:
            break;
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: ListenableBuilder(
            listenable: vm,
            builder: (context, child) => Column(
              children: [
                SessionProgressBar(vm: vm),
                Expanded(child: _buildCenter()),
                if (vm.phase != SessionPhase.completed)
                  SessionBottomPanel(vm: vm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenter() {
    return switch (vm.phase) {
      SessionPhase.countdown ||
      SessionPhase.preparingDuration => CountdownView(value: vm.countdown),
      SessionPhase.exercising => const SizedBox.expand(),
      SessionPhase.resting => RestView(
        secondsRemaining: vm.restSecondsRemaining,
        nextCircuit: vm.currentCircuit + 1,
        totalCircuits: vm.totalSets,
        onSkip: vm.skipRest,
      ),
      SessionPhase.completed => CompletedView(
        summary: vm.summary,
        onDone: () async {
          await vm.finishWorkout();
          if (!mounted) return;
          context.pop();
        },
      ),
    };
  }
}
