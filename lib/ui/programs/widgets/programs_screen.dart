import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/ui/programs/view_models/programs_view_model.dart";
import "package:workout_tracker/ui/programs/widgets/program_form_sheet.dart";

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProgramsViewModel vm = getIt<ProgramsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Programs")),
      body: ListenableBuilder(
        listenable: vm,
        builder: (_, _) => _buildBody(context, vm),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet<Widget>(
          context: context,
          builder: (context) => const ProgramFormSheet(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProgramsViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.programs.isEmpty) {
      return const Center(child: Text("No programs yet"));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: viewModel.programs.length,
      itemBuilder: (context, index) {
        final programWithCount = viewModel.programs[index];
        final program = programWithCount.program;
        final workoutCount = programWithCount.workoutCount;

        return GestureDetector(
          onTap: () => context.push("/programs/${program.id}"),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).disabledColor.withAlpha(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(program.name),
                  if (workoutCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      "$workoutCount workout${workoutCount == 1 ? "" : "s"}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
