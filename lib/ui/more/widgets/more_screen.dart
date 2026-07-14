import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/ui/more/view_models/more_view_model.dart";
import "package:workout_tracker/ui/more/widgets/more_tile.dart";
import "package:workout_tracker/ui/more/widgets/more_tile_group.dart";

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  late final MoreViewModel vm = getIt<MoreViewModel>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("More")),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: MoreTileGroup(
            title: "Workouts",
            children: [
              MoreTile(
                icon: Icons.fitness_center_outlined,
                title: "Exercises",
                trailingText: vm.exerciseCount > 0
                    ? "${vm.exerciseCount}"
                    : null,
                onTap: () => context.push("/more/exercises"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
