import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/ui/home/view_models/home_view_model.dart";
import "package:workout_tracker/ui/home/widgets/todays_workout_card.dart";

class HomeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeViewModel vm = getIt<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.activeProgram == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("No active program"),
                  TextButton(
                    onPressed: () => context.push("/programs"),
                    child: const Text("Browse programs"),
                  ),
                ],
              ),
            );
          }

          final workout = vm.todaysWorkout;
          if (workout == null) {
            return const Center(child: Text("No workouts in this program"));
          }

          return TodaysWorkoutCard(
            workout: workout,
            programName: vm.activeProgram!.name,
            totalWorkouts: vm.totalWorkouts,
            isDoneToday: vm.isDoneToday,
          );
        },
      ),
    );
  }
}
