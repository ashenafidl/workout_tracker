import "package:flutter/material.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/database/database.dart";
import "package:workout_tracker/ui/exercises/view_models/exercise_form_view_model.dart";

class ExerciseFormSheet extends StatefulWidget {
  const new({super.key, this.exercise});

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
  bool _isSelectingType = false;

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

  void _showTypeSelection() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSelectingType = true);
  }

  Future<void> _submit() async {
    final success = await _viewModel.submit();
    if (!mounted) {
      return;
    }
    if (success) {
      Navigator.pop(context);
      return;
    }

    final message = _viewModel.errorMessage ?? "Unable to add exercise";
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardInset),
          child: SingleChildScrollView(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isSelectingType
                  ? _TypeSelectionView(
                      key: const ValueKey("type-selection"),
                      name: _nameController.text.trim(),
                      description: _descriptionController.text.trim(),
                      selectedType: _viewModel.type,
                      isLoading: _viewModel.isLoading,
                      isEditing: _viewModel.isEditing,
                      onBack: () => setState(() => _isSelectingType = false),
                      onTypeSelected: (type) => _viewModel.type = type,
                      onSubmit: _submit,
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        key: const ValueKey("exercise-details"),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _viewModel.isEditing
                                ? "Edit exercise"
                                : "Add exercise",
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
                            decoration: const InputDecoration(
                              labelText: "Name",
                            ),
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
                            decoration: const InputDecoration(
                              labelText: "Description",
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: _showTypeSelection,
                              child: const Text("Continue"),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _TypeSelectionView extends StatelessWidget {
  const new({
    super.key,
    required this.name,
    required this.description,
    required this.selectedType,
    required this.isLoading,
    required this.isEditing,
    required this.onBack,
    required this.onTypeSelected,
    required this.onSubmit,
  });

  final String name;
  final String description;
  final ExerciseType selectedType;
  final bool isLoading;
  final bool isEditing;
  final VoidCallback onBack;
  final ValueChanged<ExerciseType> onTypeSelected;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: isLoading ? null : onBack,
              icon: const Icon(Icons.arrow_back),
              tooltip: "Back",
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleLarge),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        RadioGroup(
          groupValue: selectedType,
          onChanged: (value) {
            if (value != null) onTypeSelected(value);
          },
          child: Column(
            children: [
              for (final option in ExerciseType.values)
                RadioListTile<ExerciseType>(
                  value: option,
                  title: Text(option.name),
                  subtitle: Text(option.description),
                  secondary: Icon(option.icon),
                  controlAffinity: .trailing,
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : FilledButton(
                  onPressed: onSubmit,
                  child: Text(isEditing ? "Save changes" : "Add exercise"),
                ),
        ),
      ],
    );
  }
}
