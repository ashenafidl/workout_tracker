import "package:flutter/material.dart";
import "package:workout_tracker/config/dependencies.dart";
import "package:workout_tracker/core/theme/app_theme.dart";
import "package:workout_tracker/routing/router.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Workout Tracker",
      routerConfig: appRouter,
      theme: AppTheme().light,
      darkTheme: AppTheme().dark,
      themeMode: .system,
    );
  }
}
