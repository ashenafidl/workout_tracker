import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:phosphor_icons/phosphor_icons.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_config.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_result.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_sheet.dart";
import "package:workout_tracker/ui/more/view_models/more_view_model.dart";
import "package:workout_tracker/ui/more/view_models/schedule_view_model.dart";
import "package:workout_tracker/ui/more/widgets/more_tile.dart";
import "package:workout_tracker/ui/more/widgets/more_tile_group.dart";
import "package:workout_tracker/ui/more/widgets/schedule_sheet.dart";
import "package:workout_tracker/utils/format_time.dart";

class MoreScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  late final MoreViewModel vm = getIt<MoreViewModel>();
  final scheduleVm = getIt<ScheduleViewModel>();

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
      ),
    );

    if (result case DurationInputResult(:final duration)) {
      vm.setRestDuration(duration.inSeconds);
    }
  }

  Future<void> _showScheduleSheet() async {
    try {
      await scheduleVm.beginEditing();
      if (!mounted) {
        scheduleVm.cancelEditing();
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        builder: (context) => const ScheduleSheet(),
      );
      scheduleVm.cancelEditing();
    } catch (error) {
      scheduleVm.cancelEditing();
      if (!mounted) return;
      _showMessage(error.toString(), isError: true);
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
          content: Text(
            message,
            style: isError
                ? TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  )
                : null,
          ),
          backgroundColor: isError
              ? Theme.of(context).colorScheme.errorContainer
              : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("More")),
      body: ListenableBuilder(
        listenable: Listenable.merge([vm, scheduleVm]),
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
                    title: "Workout",
                    children: [
                      MoreTile(
                        icon: PhosphorIconsDuotone.barbell,
                        title: "Exercises",
                        trailing: vm.exerciseCount > 0
                            ? Text(
                                "${vm.exerciseCount}",
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline,
                                    ),
                              )
                            : null,
                        onTap: vm.isBackupBusy
                            ? null
                            : () => context.push("/more/exercises"),
                      ),
                      MoreTile(
                        icon: PhosphorIconsDuotone.timer,
                        title: "Rest Time",
                        trailing: Text(
                          formatDuration(Duration(seconds: vm.restDuration)),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                        onTap: vm.isBackupBusy
                            ? null
                            : _showRestDurationSettingDialog,
                      ),
                      MoreTile(
                        icon: PhosphorIconsDuotone.calendarDots,
                        title: "Schedule",
                        trailing: _WorkoutDaysIndicator(
                          weekdays: scheduleVm.weekdays,
                        ),
                        onTap: vm.isBackupBusy ? null : _showScheduleSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  MoreTileGroup(
                    title: "Backup & Restore",
                    children: [
                      MoreTile(
                        icon: PhosphorIconsDuotone.fileArrowUp,
                        title: "Export Backup",
                        onTap: vm.isBackupBusy ? null : _exportBackup,
                      ),
                      MoreTile(
                        icon: PhosphorIconsDuotone.fileArrowDown,
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

class _WorkoutDaysIndicator extends StatelessWidget {
  const new({required this.weekdays});

  final Set<int> weekdays;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const labels = ["M", "T", "W", "T", "F", "S", "S"];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < labels.length; index++)
          SizedBox(
            width: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (weekdays.contains(index + 1))
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(width: 5, height: 5),
                  )
                else
                  const SizedBox(width: 5, height: 5),
                const SizedBox(height: 3),
                Text(
                  labels[index],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: weekdays.contains(index + 1)
                        ? colors.primary
                        : colors.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
