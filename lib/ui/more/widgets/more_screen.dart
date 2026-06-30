import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/ui/more/view_models/more_view_model.dart";
import "package:workout_tracker/ui/more/widgets/more_tile.dart";

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
      body: ListView(
        children: [
          MoreTile(
            icon: Icons.fitness_center_outlined,
            title: "Exercises",
            trailingText: vm.exerciseCount > 0 ? "${vm.exerciseCount}" : null,
            onTap: () => context.push("/more/exercises"),
          ),
        ],
      ),
    );
  }
}
