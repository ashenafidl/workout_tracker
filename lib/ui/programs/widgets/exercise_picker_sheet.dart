import "dart:async";

import "package:flutter/material.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/core/widgets/exercise_tile.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/repositories/exercise_repo.dart";
import "package:workout_tracker/ui/exercises/widgets/exercise_type_selection_view.dart";

class ExercisePickerSheet extends StatefulWidget {
  const new({
    super.key,
    required this.onExerciseSelected,
    required this.onCreateExercise,
  });

  final void Function(ExerciseWithTypes exercise) onExerciseSelected;
  final Future<ExerciseWithTypes?> Function(
    String name,
    List<ExerciseType> types, {
    bool isBilateral,
  })
  onCreateExercise;

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  final _searchController = TextEditingController();
  List<ExerciseWithTypes> _allExercises = [];
  List<ExerciseWithTypes> _filteredExercises = [];
  bool _isLoading = true;
  bool _isSelectingType = false;
  bool _isCreating = false;
  String? _createError;
  String _newExerciseName = "";
  Set<ExerciseType> _selectedTypes = {ExerciseType.reps};
  bool _isNewExerciseBilateral = false;
  StreamSubscription<List<ExerciseWithTypes>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = getIt<ExerciseRepo>().watchAllExercisesWithTypes().listen((
      exercises,
    ) {
      if (!mounted) {
        return;
      }
      setState(() {
        _allExercises = exercises;
        _filterExercises(_searchController.text);
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _filterExercises(String query) {
    if (query.trim().isEmpty) {
      _filteredExercises = _allExercises;
      return;
    }

    final lower = query.toLowerCase();
    _filteredExercises = _allExercises
        .where(
          (exercise) => exercise.exercise.name.toLowerCase().contains(lower),
        )
        .toList();
  }

  void _showTypeSelection() {
    FocusScope.of(context).unfocus();
    setState(() {
      _newExerciseName = _searchController.text.trim();
      _selectedTypes = {ExerciseType.reps};
      _isNewExerciseBilateral = false;
      _isSelectingType = true;
    });
  }

  Future<void> _createExercise() async {
    setState(() => _isCreating = true);
    try {
      final exerciseWithTypes = await widget.onCreateExercise(
        _newExerciseName,
        _selectedTypes.toList(),
        isBilateral: _isNewExerciseBilateral,
      );
      if (!mounted) {
        return;
      }
      if (exerciseWithTypes != null) {
        Navigator.pop(context, exerciseWithTypes);
        return;
      }
      setState(() {
        _isCreating = false;
        _createError = "Unable to create exercise";
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCreating = false;
        _createError = error.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.95 - keyboardInset,
        ),
        child: SingleChildScrollView(
          child: _isSelectingType
              ? ExerciseTypeSelectionView(
                  name: _newExerciseName,
                  description: "",
                  selectedTypes: _selectedTypes,
                  isBilateral: _isNewExerciseBilateral,
                  onBilateralChanged: (value) =>
                      setState(() => _isNewExerciseBilateral = value),
                  isLoading: _isCreating,
                  submitLabel: "Create exercise",
                  onBack: () => setState(() => _isSelectingType = false),
                  onTypeToggled: (type) => setState(() {
                    _createError = null;
                    if (_selectedTypes.contains(type)) {
                      _selectedTypes = Set.of(_selectedTypes)..remove(type);
                    } else {
                      _selectedTypes = Set.of(_selectedTypes)..add(type);
                    }
                  }),
                  errorMessage: _createError,
                  onSubmit: _createExercise,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Add exercise",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      textCapitalization: .words,
                      decoration: const InputDecoration(
                        labelText: "Search exercises",
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() => _filterExercises(value));
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_filteredExercises.isEmpty &&
                        _searchController.text.trim().isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text("No exercises yet. Create one below."),
                        ),
                      )
                    else ...[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exerciseWithTypes = _filteredExercises[index];

                          return ExerciseTile(
                            exerciseWithTypes: exerciseWithTypes,
                            onTap: () {
                              widget.onExerciseSelected(exerciseWithTypes);
                              Navigator.pop(context, exerciseWithTypes);
                            },
                          );
                        },
                      ),
                      const Divider(),
                      if (_searchController.text.trim().isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: Text(
                            "Create '${_searchController.text.trim()}'",
                          ),
                          onTap: _showTypeSelection,
                        ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
