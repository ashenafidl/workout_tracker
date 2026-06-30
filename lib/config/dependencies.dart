import "package:get_it/get_it.dart";
import "package:workout_tracker/database/database.dart";

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // DB
  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);
}
