import "package:flutter/material.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/core/widgets/exercise_side_badge.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_config.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_result.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_sheet.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/models/programs.dart";
import "package:workout_tracker/database/database.dart";
import "package:workout_tracker/ui/programs/view_models/workout_view_model.dart";
import "package:workout_tracker/ui/programs/widgets/exercise_picker_sheet.dart";
import "package:workout_tracker/ui/programs/widgets/exercise_side_sheet.dart";

class WorkoutScreen extends StatefulWidget {
  const new({
    super.key,
    required this.programId,
    this.workoutId,
    this.initialName,
    this.initialSets,
    this.initialKind,
    this.initialRestDurationSeconds,
    this.initialExercises,
  });

  final String programId;
  final int? workoutId;
  final String? initialName;
  final int? initialSets;
  final WorkoutKind? initialKind;
  final int? initialRestDurationSeconds;
  final List<WorkoutExerciseDetail>? initialExercises;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late final WorkoutViewModel _viewModel;
  late final TextEditingController _nameController;
  late final TextEditingController _setsController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<WorkoutViewModel>();
    _nameController = TextEditingController(text: widget.initialName ?? "");
    _setsController = TextEditingController(
      text: (widget.initialSets ?? 1).toString(),
    );

    if (widget.workoutId != null &&
        widget.initialName != null &&
        widget.initialExercises != null) {
      _viewModel.loadWorkout(
        workoutId: widget.workoutId!,
        name: widget.initialName!,
        sets: widget.initialSets ?? 1,
        kind: widget.initialKind ?? WorkoutKind.standard,
        restDurationSeconds: widget.initialRestDurationSeconds,
        exercises: widget.initialExercises!,
      );
    }

    _nameController.addListener(_syncViewModel);
    _setsController.addListener(_syncViewModelSets);
  }

  @override
  void dispose() {
    _nameController.removeListener(_syncViewModel);
    _nameController.dispose();
    _setsController.removeListener(_syncViewModelSets);
    _setsController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _syncViewModel() {
    _viewModel.name = _nameController.text;
  }

  void _syncViewModelSets() {
    final parsed = int.tryParse(_setsController.text);
    if (parsed != null && parsed > 0) {
      _viewModel.sets = parsed;
    }
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final success = await _viewModel.submit(widget.programId);
    if (!mounted) {
      return;
    }
    if (success) {
      Navigator.pop(context);
      return;
    }

    final message = _viewModel.errorMessage ?? "Unable to save workout";
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _viewModel.kind == WorkoutKind.challenge
                  ? (_viewModel.isEditing ? "Edit challenge" : "Add challenge")
                  : (_viewModel.isEditing ? "Edit workout" : "Add workout"),
            ),
          ),
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Form(
              key: _formKey,
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                header: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: "Workout name",
                      ),
                      validator: (value) {
                        final trimmed = (value ?? "").trim();
                        if (trimmed.isEmpty) {
                          return "Workout name is required";
                        }
                        return null;
                      },
                    ),

                    SegmentedButton<WorkoutKind>(
                      segments: const [
                        ButtonSegment(
                          value: WorkoutKind.standard,
                          icon: Icon(Icons.repeat_rounded),
                          label: Text("Standard"),
                        ),
                        ButtonSegment(
                          value: WorkoutKind.challenge,
                          icon: Icon(Icons.emoji_events_outlined),
                          label: Text("Challenge"),
                        ),
                      ],
                      selected: {_viewModel.kind},
                      onSelectionChanged: (selection) =>
                          _viewModel.kind = selection.first,
                    ),
                    if (_viewModel.kind == WorkoutKind.standard) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _setsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Sets (circuit repeats)",
                        ),
                        validator: (value) {
                          final parsed = int.tryParse(value ?? "");
                          if (parsed == null || parsed < 1) {
                            return "Must be at least 1";
                          }
                          return null;
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.timer_outlined),
                        title: const Text("Rest between sets"),
                        subtitle: Text(_viewModel.restLabel),
                        trailing: _viewModel.restDurationSeconds != null
                            ? IconButton(
                                icon: const Icon(Icons.restart_alt),
                                tooltip: "Use app default",
                                onPressed: () =>
                                    _viewModel.restDurationSeconds = null,
                              )
                            : null,
                        onTap: _showRestDurationPicker,
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_viewModel.exercises.isNotEmpty) ...[
                      Text(
                        "Exercises",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          "No exercises added yet",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ),
                  ],
                ),
                footer: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showExercisePicker,
                      icon: const Icon(Icons.add),
                      label: const Text("Add exercise"),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: _viewModel.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : FilledButton(
                              onPressed: _submit,
                              child: Text(
                                _viewModel.isEditing
                                    ? "Save changes"
                                    : "Add workout",
                              ),
                            ),
                    ),
                  ],
                ),
                itemCount: _viewModel.exercises.length,
                onReorderItem: _viewModel.reorderExercises,
                itemBuilder: (context, index) {
                  final input = _viewModel.exercises[index];
                  return _ExerciseRow(
                    key: ValueKey("exercise_$index"),
                    index: index,
                    input: input,
                    viewModel: _viewModel,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRestDurationPicker() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await showModalBottomSheet<UnitInputResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => UnitInputSheet(
        title: "Rest Duration",
        config: DurationInputConfig(
          initialDuration: Duration(
            seconds:
                _viewModel.restDurationSeconds ??
                _viewModel.defaultRestDurationSeconds,
          ),
        ),
      ),
    );

    if (result case DurationInputResult(:final duration)) {
      _viewModel.restDurationSeconds = duration.inSeconds;
    }
  }

  Future<void> _showExercisePicker() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final exercise = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => ExercisePickerSheet(
        onExerciseSelected: (_) {},
        onCreateExercise: (name, type, {isBilateral = false}) => _viewModel
            .createAndAddExercise(name, type, isBilateral: isBilateral),
      ),
    );

    if (exercise == null || !mounted) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    // Bilateral exercises get a side before their target, so the row is fully
    // specified in one pass. Dismissing the sheet drops the exercise.
    ExerciseSide? side;
    if (exercise.isBilateral) {
      final selected = await ExerciseSideSheet.show(
        context,
        exerciseName: exercise.name,
      );
      if (selected == null || !mounted) {
        return;
      }
      side = selected;
    } else {
      side = null;
    }

    final config = switch (exercise.type) {
      ExerciseType.reps => const IntegerInputConfig(
        initialValue: 10,
        label: "reps",
      ),
      ExerciseType.duration => const DurationInputConfig(
        initialDuration: Duration(seconds: 10),
      ),
    };

    final result = await showModalBottomSheet<UnitInputResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => UnitInputSheet(
        title: exercise.name,
        subtitle: exercise.type.name,
        config: config,
      ),
    );

    if (result case IntegerInputResult(:final value)) {
      _viewModel.addExercise(exercise, side: side, targetReps: value);
    } else if (result case DurationInputResult(:final duration)) {
      _viewModel.addExercise(
        exercise,
        side: side,
        targetDurationSeconds: duration.inSeconds,
      );
    }
  }
}

class _ExerciseRow extends StatelessWidget {
  const new({
    super.key,
    required this.index,
    required this.input,
    required this.viewModel,
  });

  final int index;
  final WorkoutExerciseInput input;
  final WorkoutViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.drag_handle),
      title: ExerciseTitleWithSide(name: input.exerciseName, side: input.side),
      subtitle: Text(
        input.side == ExerciseSide.both
            ? "${input.targetLabel} • left then right"
            : input.targetLabel,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showTargetSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => viewModel.removeExercise(index),
          ),
        ],
      ),
    );
  }

  Future<void> _showTargetSheet(BuildContext context) async {
    // Side first, so the target sheet and the row stay in sync afterwards.
    if (input.isBilateral) {
      final side = await ExerciseSideSheet.show(
        context,
        exerciseName: input.exerciseName,
        initialSide: input.side ?? ExerciseSide.both,
      );
      if (side == null || !context.mounted) {
        return;
      }
      viewModel.updateExerciseSide(index, side);
    }

    if (!context.mounted) {
      return;
    }

    final config = switch (input.type) {
      ExerciseType.reps => IntegerInputConfig(
        initialValue: input.targetReps ?? 10,
        label: "reps",
      ),
      ExerciseType.duration => DurationInputConfig(
        initialDuration: Duration(seconds: input.targetDurationSeconds ?? 10),
      ),
    };

    final result = await showModalBottomSheet<UnitInputResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => UnitInputSheet(
        title: input.exerciseName,
        subtitle: input.targetLabel,
        config: config,
      ),
    );

    if (result == null) {
      return;
    }

    switch (input.type) {
      case ExerciseType.reps:
        if (result case IntegerInputResult(:final value)) {
          viewModel.updateExerciseTarget(index, targetReps: value);
        }
      case ExerciseType.duration:
        if (result case DurationInputResult(:final duration)) {
          viewModel.updateExerciseTarget(
            index,
            targetDurationSeconds: duration.inSeconds,
          );
        }
    }
  }
}
