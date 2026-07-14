import "package:flutter/material.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/ui/exercises/view_models/exercise_list_view_model.dart";
import "package:workout_tracker/ui/exercises/widgets/exercise_form_sheet.dart";

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ExerciseListViewModel vm = getIt<ExerciseListViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Exercises")),
      body: ListenableBuilder(
        listenable: vm,
        builder: (_, _) => _buildBody(vm),
      ),
      floatingActionButton: FloatingActionButton(
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
    );
  }
}

Widget _buildBody(ExerciseListViewModel viewModel) {
  if (viewModel.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (viewModel.exercises.isEmpty) {
    return const Center(child: Text("No exercises yet"));
  }

  return ListView.builder(
    itemCount: viewModel.exercises.length,
    itemBuilder: (context, index) {
      final exercise = viewModel.exercises[index];

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
          final deleted = await viewModel.deleteExercise(exercise.id);
          if (!deleted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Unable to delete exercise")),
            );
          }
          return deleted;
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Text(exercise.name),
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (sheetContext) => ExerciseFormSheet(exercise: exercise),
            );
          },
        ),
      );
    },
  );
}
