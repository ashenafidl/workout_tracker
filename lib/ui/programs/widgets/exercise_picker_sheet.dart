import "dart:async";

import "package:flutter/material.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/repositories/exercise_repo.dart";
import "package:workout_tracker/database/database.dart";
import "package:workout_tracker/ui/exercises/widgets/exercise_type_selection_view.dart";

class ExercisePickerSheet extends StatefulWidget {
  const new({
    super.key,
    required this.onExerciseSelected,
    required this.onCreateExercise,
  });

  final void Function(Exercise exercise) onExerciseSelected;
  final Future<Exercise?> Function(String name, ExerciseType type)
  onCreateExercise;

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  final _searchController = TextEditingController();
  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  bool _isLoading = true;
  bool _isSelectingType = false;
  bool _isCreating = false;
  String _newExerciseName = "";
  ExerciseType _selectedType = ExerciseType.reps;
  StreamSubscription<List<Exercise>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = getIt<ExerciseRepo>().watchAllExercises().listen((
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
        .where((exercise) => exercise.name.toLowerCase().contains(lower))
        .toList();
  }

  void _showTypeSelection() {
    FocusScope.of(context).unfocus();
    setState(() {
      _newExerciseName = _searchController.text.trim();
      _selectedType = ExerciseType.reps;
      _isSelectingType = true;
    });
  }

  Future<void> _createExercise() async {
    setState(() => _isCreating = true);
    final exercise = await widget.onCreateExercise(
      _newExerciseName,
      _selectedType,
    );
    if (!mounted) {
      return;
    }
    if (exercise != null) {
      Navigator.pop(context, exercise);
      return;
    }
    setState(() => _isCreating = false);
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
                  selectedType: _selectedType,
                  isLoading: _isCreating,
                  submitLabel: "Create exercise",
                  onBack: () => setState(() => _isSelectingType = false),
                  onTypeSelected: (type) =>
                      setState(() => _selectedType = type),
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
                          final exercise = _filteredExercises[index];
                          return ListTile(
                            leading: Icon(exercise.type.icon),
                            title: Text(exercise.name),
                            subtitle: exercise.description != null
                                ? Text(
                                    exercise.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () {
                              widget.onExerciseSelected(exercise);
                              Navigator.pop(context, exercise);
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
