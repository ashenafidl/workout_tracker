import "dart:async";

import "package:flutter/material.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/data/repositories/exercise_repo.dart";
import "package:workout_tracker/database/database.dart";

class ExercisePickerSheet extends StatefulWidget {
  const new({
    super.key,
    required this.onExerciseSelected,
    required this.onCreateExercise,
  });

  final void Function(Exercise exercise) onExerciseSelected;
  final Future<Exercise?> Function(String name) onCreateExercise;

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  final _searchController = TextEditingController();
  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  bool _isLoading = true;
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
    } else {
      final lower = query.toLowerCase();
      _filteredExercises = _allExercises
          .where((e) => e.name.toLowerCase().contains(lower))
          .toList();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Add exercise", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Search exercises",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _filterExercises(value);
                });
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
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _filteredExercises[index];
                    return ListTile(
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
              ),
              if (_searchController.text.trim().isNotEmpty) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text("Create '${_searchController.text.trim()}'"),
                  onTap: () async {
                    final name = _searchController.text.trim();
                    final navigator = Navigator.of(context);
                    final exercise = await widget.onCreateExercise(name);
                    if (exercise != null && mounted) {
                      navigator.pop(exercise);
                    }
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
