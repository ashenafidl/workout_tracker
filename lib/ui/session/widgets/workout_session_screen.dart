import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/data/models/workout_session_args.dart";
import "package:workout_tracker/database/database.dart";
import "package:workout_tracker/ui/session/view_models/workout_session_view_model.dart";
import "package:workout_tracker/ui/session/widgets/completed_view.dart";
import "package:workout_tracker/ui/session/widgets/countdown_view.dart";
import "package:workout_tracker/ui/session/widgets/rest_view.dart";
import "package:workout_tracker/ui/session/widgets/session_bottom_panel.dart";
import "package:workout_tracker/ui/session/widgets/session_progress_bar.dart";

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
    vm.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (vm.phase == SessionPhase.completed) return true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Quite workout?"),
        content: const Text("Your progress for this session will be lost."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Quit",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep going"),
          ),
        ],
      ),
    );

    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final can = await _onWillPop();
        if (can && context.mounted) context.pop();
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
      SessionPhase.countdown => CountdownView(value: vm.countdown),
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
