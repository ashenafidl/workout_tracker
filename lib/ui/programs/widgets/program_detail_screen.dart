import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/data/models/exercises.dart";
import "package:workout_tracker/data/models/workout_session_args.dart";
import "package:workout_tracker/ui/programs/view_models/program_detail_view_model.dart";
import "package:workout_tracker/ui/programs/widgets/workout_screen.dart";

class ProgramDetailScreen extends StatefulWidget {
  const new({super.key, required this.programId});

  final int programId;

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  late final ProgramDetailViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = getIt<ProgramDetailViewModel>();
    vm.loadProgram(widget.programId);
  }

  Future<void> _startProgram() async {
    final nextWorkout = vm.nextWorkoutIndex;
    if (!mounted || nextWorkout == null) return;

    vm.setActive(widget.programId);

    context.push(
      "/session",
      extra: WorkoutSessionArgs(
        workoutWithExercises: nextWorkout,
        programId: widget.programId,
        workoutIndex: nextWorkout.workout.position,
        totalWorkoutsInProgram: await vm.getWorkoutCount(widget.programId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: _showRenameDialog,
              child: Text(vm.program?.name ?? ""),
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == "delete") {
                    _showDeleteDialog();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: "delete",
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        const Text("Delete program"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: _buildBody(),
          floatingActionButton: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .end,
            children: [
              if (vm.workouts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FloatingActionButton.extended(
                    heroTag: "start",
                    onPressed: _startProgram,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text("Start program"),
                  ),
                ),
              FloatingActionButton(
                heroTag: "add",
                onPressed: _openWorkoutScreen,
                child: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.workouts.isEmpty) {
      return const Center(child: Text("No workouts yet"));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: vm.workouts.length,
      itemBuilder: (context, index) {
        final workoutWithExercises = vm.workouts[index];
        final workout = workoutWithExercises.workout;
        final exercises = workoutWithExercises.exercises;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openWorkoutScreen(
              workoutId: workout.id,
              name: workout.name,
              sets: workout.sets,
              exercises: exercises,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Day ${index + 1}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          workout.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        "${workout.sets} set${workout.sets == 1 ? "" : "s"}",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final we in exercises) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(we.exercise.name)),
                          Text(
                            "${we.reps} reps",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
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

  void _showRenameDialog() {
    final controller = TextEditingController(text: vm.program?.name ?? "");
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename program"),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: "Program name"),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              vm.renameProgram(controller.text);
              Navigator.of(context).pop();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    final programName = vm.program?.name ?? "";
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete program"),
        content: Text(
          "This will permanently delete $programName and all its workouts. "
          "This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              final deleted = await vm.deleteProgram();
              if (!context.mounted) {
                return;
              }
              Navigator.of(context).pop();
              if (deleted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _openWorkoutScreen({
    int? workoutId,
    String? name,
    int? sets,
    List<WorkoutExerciseDetail>? exercises,
  }) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutScreen(
          programId: widget.programId.toString(),
          workoutId: workoutId,
          initialName: name,
          initialSets: sets,
          initialExercises: exercises,
        ),
      ),
    );
  }
}
