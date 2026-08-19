import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_config.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_result.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_sheet.dart";
import "package:workout_tracker/ui/more/view_models/more_view_model.dart";
import "package:workout_tracker/ui/more/widgets/more_tile.dart";
import "package:workout_tracker/ui/more/widgets/more_tile_group.dart";
import "package:workout_tracker/utils/format_time.dart";

class MoreScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  late final MoreViewModel vm = getIt<MoreViewModel>();

  Future<void> _showRestDurationSettingDialog() async {
    final result = await showModalBottomSheet<UnitInputResult>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => UnitInputSheet(
        title: "Rest Duration",
        config: DurationInputConfig(
          initialDuration: Duration(seconds: vm.restDuration),
        ),
        // initialValue: "${vm.restDuration}",
      ),
    );

    if (result case DurationInputResult(:final duration)) {
      vm.setRestDuration(duration.inSeconds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("More")),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            MoreTileGroup(
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
                MoreTile(
                  icon: Icons.timer_outlined,
                  title: "Rest Time",
                  trailingText: formatDuration(
                    Duration(seconds: vm.restDuration),
                  ),
                  onTap: _showRestDurationSettingDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
