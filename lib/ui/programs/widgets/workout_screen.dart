import "package:flutter/material.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_config.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_result.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_sheet.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/database/database.dart";
import "package:workout_tracker/ui/programs/view_models/workout_view_model.dart";
import "package:workout_tracker/ui/programs/widgets/exercise_picker_sheet.dart";

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.programId,
    this.workoutId,
    this.initialName,
    this.initialSets,
    this.initialExercises,
  });

  final String programId;
  final int? workoutId;
  final String? initialName;
  final int? initialSets;
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_viewModel.isEditing ? "Edit workout" : "Add workout"),
          ),
          body: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: TextFormField(
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
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: TextFormField(
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
                ),
                const SizedBox(height: 16),
                if (_viewModel.exercises.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Exercises",
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                if (_viewModel.exercises.isNotEmpty) const SizedBox(height: 8),
                Expanded(
                  child: _viewModel.exercises.isEmpty
                      ? Center(
                          child: Text(
                            "No exercises added yet",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        )
                      : ReorderableListView.builder(
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: OutlinedButton.icon(
                    onPressed: _showExercisePicker,
                    icon: const Icon(Icons.add),
                    label: const Text("Add exercise"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: SizedBox(
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showExercisePicker() async {
    final exercise = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => ExercisePickerSheet(
        onExerciseSelected: (_) {},
        onCreateExercise: (name) => _viewModel.createAndAddExercise(name),
      ),
    );

    if (exercise != null && mounted) {
      final result = await showModalBottomSheet<UnitInputResult>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) => UnitInputSheet(
          title: exercise.name,
          subtitle: "Reps",
          config: const IntegerInputConfig(initialValue: 10),
        ),
      );

      if (result case IntegerInputResult(:final value)) {
        _viewModel.addExercise(exercise, reps: value);
      }
    }
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
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
      leading: const Icon(Icons.drag_handle),
      title: Text(input.exerciseName),
      subtitle: Text("${input.reps} reps"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showRepsSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => viewModel.removeExercise(index),
          ),
        ],
      ),
    );
  }

  void _showRepsSheet(BuildContext context) {
    showModalBottomSheet<UnitInputResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => UnitInputSheet(
        title: input.exerciseName,
        subtitle: "Reps",
        config: IntegerInputConfig(initialValue: input.reps),
      ),
    ).then((result) {
      if (result case IntegerInputResult(:final value)) {
        viewModel.updateExerciseReps(index, value);
      }
    });
  }
}
