import "package:flutter/material.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/database/database.dart";
import "package:workout_tracker/ui/exercises/view_models/exercise_form_view_model.dart";

class ExerciseFormSheet extends StatefulWidget {
  const ExerciseFormSheet({super.key, this.exercise});

  final Exercise? exercise;

  @override
  State<ExerciseFormSheet> createState() => _ExerciseFormSheetState();
}

class _ExerciseFormSheetState extends State<ExerciseFormSheet> {
  late final ExerciseFormViewModel _viewModel;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final FocusNode _nameFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<ExerciseFormViewModel>();
    if (widget.exercise != null) {
      _viewModel.loadExercise(widget.exercise!);
    }
    _nameController = TextEditingController(text: _viewModel.name);
    _descriptionController = TextEditingController(
      text: _viewModel.description,
    );
    _nameController.addListener(_syncViewModel);
    _descriptionController.addListener(_syncViewModel);
  }

  @override
  void dispose() {
    _nameController.removeListener(_syncViewModel);
    _descriptionController.removeListener(_syncViewModel);
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _syncViewModel() {
    _viewModel.name = _nameController.text;
    _viewModel.description = _descriptionController.text;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final success = await _viewModel.submit();
    if (!mounted) {
      return;
    }
    if (success) {
      Navigator.pop(context);
      return;
    }

    final message = _viewModel.errorMessage ?? "Unable to add exercise";
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
                  _viewModel.isEditing ? "Edit exercise" : "Add exercise",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  textCapitalization: .words,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: "Name"),
                  validator: (value) {
                    final trimmed = (value ?? "").trim();
                    if (trimmed.isEmpty) {
                      return "Name is required";
                    }
                    if (trimmed.length > 100) {
                      return "Name must be 100 characters or fewer";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: _viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton(
                          onPressed: _nameController.text.trim().isEmpty
                              ? null
                              : _submit,
                          child: Text(
                            _viewModel.isEditing
                                ? "Save changes"
                                : "Add exercise",
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
}
