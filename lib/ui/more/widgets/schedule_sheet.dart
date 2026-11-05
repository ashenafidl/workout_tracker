import "package:material_ui/material_ui.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/ui/more/view_models/schedule_view_model.dart";

class ScheduleSheet extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = getIt<ScheduleViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (vm.errorMessage == null) return;
      final message = vm.errorMessage!;
      vm.clearError();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => Column(
          mainAxisSize: .min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Workout days", style: Theme.of(context).textTheme.titleLarge),
            Text(
              "Off days won't affect your streak if you miss a workout on those days.",
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: 7,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final weekday = index + 1;
                  final selected = vm.weekdays.contains(weekday);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (_) => vm.toggle(weekday),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    title: Text(
                      _dayLabel(weekday),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: vm.isSaving
                    ? null
                    : () async {
                        final saved = await vm.save();
                        if (saved && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayLabel(int weekday) => switch (weekday) {
    1 => "Monday",
    2 => "Tuesday",
    3 => "Wednesday",
    4 => "Thursday",
    5 => "Friday",
    6 => "Saturday",
    _ => "Sunday",
  };
}
