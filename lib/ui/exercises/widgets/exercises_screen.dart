import "package:material_ui/material_ui.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/core/widgets/exercise_tile.dart";
import "package:workout_tracker/ui/exercises/view_models/exercise_list_view_model.dart";
import "package:workout_tracker/ui/exercises/widgets/exercise_form_sheet.dart";

class ExercisesScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _isSearching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();
    _searchController.clear();
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final ExerciseListViewModel vm = getIt<ExerciseListViewModel>();

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSearching) {
          _closeSearch();
        }
      },
      child: Scaffold(
        body: ListenableBuilder(
          listenable: vm,
          builder: (_, _) => _buildBody(vm),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: "add_exercise",
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (sheetContext) => const ExerciseFormSheet(),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody(ExerciseListViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _searchController,
      builder: (context, searchValue, _) {
        final normalizedQuery = searchValue.text.trim().toLowerCase();

        final exercises = normalizedQuery.isEmpty
            ? viewModel.exercises
            : viewModel.exercises.where((exerciseWithTypes) {
                return exerciseWithTypes.exercise.name.toLowerCase().contains(
                  normalizedQuery,
                );
              }).toList();

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              title: _isSearching
                  ? TextField(
                      key: const ValueKey("search_text_field"),
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: "Search exercises",
                        border: InputBorder.none,
                      ),
                    )
                  : const Text("Exercises"),
              actions: [
                if (_isSearching)
                  IconButton(
                    tooltip: "Close search",
                    icon: const Icon(Icons.close),
                    onPressed: _closeSearch,
                  )
                else
                  IconButton(
                    tooltip: "Search exercises",
                    icon: const Icon(Icons.search),
                    onPressed: _openSearch,
                  ),
              ],
            ),
            if (viewModel.exercises.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text("No exercises yet")),
              )
            else if (exercises.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text("No matching exercises")),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final exerciseWithTypes = exercises[index];
                  final exercise = exerciseWithTypes.exercise;

                  return Dismissible(
                    key: ValueKey(exercise.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Theme.of(context).colorScheme.errorContainer,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: Icon(
                        Icons.delete,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    confirmDismiss: (_) async {
                      final deleted = await viewModel.deleteExercise(
                        exercise.id,
                      );

                      if (!deleted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Unable to delete exercise"),
                          ),
                        );
                      }

                      return deleted;
                    },
                    child: ExerciseTile(
                      exerciseWithTypes: exerciseWithTypes,
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (sheetContext) =>
                              ExerciseFormSheet(exercise: exerciseWithTypes),
                        );
                      },
                    ),
                  );
                }, childCount: exercises.length),
              ),
          ],
        );
      },
    );
  }
}
