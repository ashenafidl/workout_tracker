import "package:get_it/get_it.dart";
import "package:workout_tracker/data/repositories/exercise_repository.dart";
import "package:workout_tracker/database/database.dart";
import "package:workout_tracker/ui/exercises/view_models/exercise_list_view_model.dart";
import "package:workout_tracker/ui/more/view_models/more_view_model.dart";

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // DB
  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);

  // Repositories
  getIt.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepository(getIt<AppDatabase>()),
  );

  // ViewModels
  getIt.registerFactory<MoreViewModel>(
    () => MoreViewModel(getIt<ExerciseRepository>()),
  );
  getIt.registerFactory<ExerciseListViewModel>(
    () => ExerciseListViewModel(getIt<ExerciseRepository>()),
  );
}
