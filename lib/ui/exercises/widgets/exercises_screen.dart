import "package:flutter/material.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/ui/exercises/view_models/exercise_list_view_model.dart";

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ExerciseListViewModel vm = getIt<ExerciseListViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Exercises")),
      body: _buildBody(vm),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
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

  return ListView.separated(
    itemCount: viewModel.exercises.length,
    separatorBuilder: (_, _) => const Divider(height: 1),
    itemBuilder: (context, index) {
      final exercise = viewModel.exercises[index];
      return ListTile(
        title: Text(exercise.name),
        trailing: const Icon(Icons.chevron_right),
      );
    },
  );
}
