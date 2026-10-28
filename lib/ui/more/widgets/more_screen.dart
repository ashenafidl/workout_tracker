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

  Future<void> _exportBackup() async {
    try {
      final saved = await vm.exportBackup();
      if (!mounted || !saved) return;
      _showMessage("Backup exported successfully.");
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _importBackup() async {
    try {
      final backup = await vm.selectBackup();
      if (!mounted || backup == null) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Replace all app data?"),
          content: Text(
            "This will replace your existing workouts, history, settings, "
            "and other backed-up data with ${backup.summary}. This cannot "
            "be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Replace data"),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;

      await vm.restoreBackup(backup);
      if (!mounted) return;
      _showMessage("Backup restored successfully.");
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString(), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("More")),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => Column(
          children: [
            SizedBox(
              height: 2,
              child: vm.isBackupBusy ? const LinearProgressIndicator() : null,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                        onTap: vm.isBackupBusy
                            ? null
                            : () => context.push("/more/exercises"),
                      ),
                      MoreTile(
                        icon: Icons.timer_outlined,
                        title: "Rest Time",
                        trailingText: formatDuration(
                          Duration(seconds: vm.restDuration),
                        ),
                        onTap: vm.isBackupBusy
                            ? null
                            : _showRestDurationSettingDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  MoreTileGroup(
                    title: "Backup & Restore",
                    children: [
                      MoreTile(
                        icon: Icons.upload_file_outlined,
                        title: "Export Backup",
                        onTap: vm.isBackupBusy ? null : _exportBackup,
                      ),
                      MoreTile(
                        icon: Icons.download_outlined,
                        title: "Import Backup",
                        onTap: vm.isBackupBusy ? null : _importBackup,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
