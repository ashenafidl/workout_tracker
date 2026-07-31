import "package:flutter/material.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/ui/home/view_models/home_view_model.dart";
import "package:workout_tracker/ui/home/widgets/todays_workout_card.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

          return const TodaysWorkoutCard();
        },
      ),
    );
  }
}
