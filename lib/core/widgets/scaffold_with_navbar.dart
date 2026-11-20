import "package:drift/drift.dart";
import "package:flutter/foundation.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:phosphor_icons/phosphor_icons.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/database/database.dart";

class ScaffoldWithNavbar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const new({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the active tab again pops to its root instead of no-op.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final db = getIt<AppDatabase>();

    return Scaffold(
      floatingActionButtonLocation: .startFloat,

      body: navigationShell,

      bottomNavigationBar: BottomNavigationBar(
        type: .fixed,
        currentIndex: navigationShell.currentIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onTap,
        items: [
          const BottomNavigationBarItem(
            icon: PhosphorIcon(PhosphorIconsDuotone.house),
            label: "Home",
          ),
          const BottomNavigationBarItem(
            icon: PhosphorIcon(PhosphorIconsDuotone.calendarBlank),
            label: "Programs",
          ),
          const BottomNavigationBarItem(
            icon: PhosphorIcon(PhosphorIconsDuotone.chartBar),
            label: "Stats",
          ),
          const BottomNavigationBarItem(
            icon: PhosphorIcon(PhosphorIconsDuotone.clockCounterClockwise),
            label: "History",
          ),
          const BottomNavigationBarItem(
            icon: PhosphorIcon(PhosphorIconsDuotone.list),
            label: "More",
          ),
        ],
      ),

      floatingActionButton: kDebugMode
          ? FloatingActionButton(
              heroTag: "delete_all_tables",
              backgroundColor: cs.errorContainer,
              foregroundColor: cs.onErrorContainer,
              mini: true,
              child: const PhosphorIcon(PhosphorIconsDuotone.trash),
              onPressed: () async {
                final m = Migrator(db);
                for (final table in db.allTables) {
                  await m.deleteTable(table.actualTableName);
                  await m.createTable(table);
                }
                db.markTablesUpdated(db.allTables);
              },
            )
          : null,
    );
  }
}
