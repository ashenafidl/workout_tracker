import "package:flutter/material.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/ui/programs/view_models/workout_sheet_view_model.dart";
import "package:workout_tracker/ui/programs/widgets/exercise_picker_sheet.dart";

class WorkoutSheet extends StatefulWidget {
  const WorkoutSheet({
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
  State<WorkoutSheet> createState() => _WorkoutSheetState();
}

class _WorkoutSheetState extends State<WorkoutSheet> {
  late final WorkoutSheetViewModel _viewModel;
  late final TextEditingController _nameController;
  late final TextEditingController _setsController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<WorkoutSheetViewModel>();
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
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardInset),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _viewModel.isEditing ? "Edit workout" : "Add workout",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: "Workout name"),
                  validator: (value) {
                    final trimmed = (value ?? "").trim();
                    if (trimmed.isEmpty) {
                      return "Workout name is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 16),
                if (_viewModel.exercises.isNotEmpty) ...[
                  Text(
                    "Exercises",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: ReorderableListView.builder(
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
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  onPressed: _showExercisePicker,
                  icon: const Icon(Icons.add),
                  label: const Text("Add exercise"),
                ),
                const SizedBox(height: 24),
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
          ),
        );
      },
    );
  }

  void _showExercisePicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => ExercisePickerSheet(
        onExerciseSelected: _viewModel.addExercise,
        onCreateExercise: (name) async {
          final exercise = await _viewModel.createAndAddExercise(name);
          if (exercise != null) {
            _viewModel.addExercise(exercise);
          }
          return exercise;
        },
      ),
    );
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
  final WorkoutSheetViewModel viewModel;

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
            onPressed: () => _showRepsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => viewModel.removeExercise(index),
          ),
        ],
      ),
    );
  }

  void _showRepsDialog(BuildContext context) {
    final controller = TextEditingController(text: input.reps.toString());
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reps"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Reps"),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              if (parsed != null && parsed > 0) {
                viewModel.updateExerciseReps(index, parsed);
              }
              Navigator.of(context).pop();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
