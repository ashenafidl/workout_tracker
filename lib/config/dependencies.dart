import "package:get_it/get_it.dart";
import "package:workout_tracker/data/repositories/exercise_repository.dart";
import "package:workout_tracker/data/repositories/program_repository.dart";
import "package:workout_tracker/data/repositories/workout_repository.dart";
import "package:workout_tracker/database/database.dart";
import "package:workout_tracker/ui/exercises/view_models/exercise_form_view_model.dart";
import "package:workout_tracker/ui/exercises/view_models/exercise_list_view_model.dart";
import "package:workout_tracker/ui/more/view_models/more_view_model.dart";
import "package:workout_tracker/ui/programs/view_models/program_detail_view_model.dart";
import "package:workout_tracker/ui/programs/view_models/programs_view_model.dart";
import "package:workout_tracker/ui/programs/view_models/workout_view_model.dart";

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // DB
  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);

  // Repositories
  getIt.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepository(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<ProgramRepository>(
    () => ProgramRepository(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<WorkoutRepository>(
    () => WorkoutRepository(getIt<AppDatabase>()),
  );

  // ViewModels
  getIt.registerFactory<MoreViewModel>(
    () => MoreViewModel(getIt<ExerciseRepository>()),
  );
  getIt.registerFactory<ExerciseListViewModel>(
    () => ExerciseListViewModel(getIt<ExerciseRepository>()),
  );
  getIt.registerFactory<ExerciseFormViewModel>(
    () => ExerciseFormViewModel(getIt<ExerciseRepository>()),
  );
  getIt.registerFactory<ProgramsViewModel>(
    () => ProgramsViewModel(getIt<ProgramRepository>()),
  );
  getIt.registerFactory<ProgramDetailViewModel>(
    () => ProgramDetailViewModel(
      getIt<ProgramRepository>(),
      getIt<WorkoutRepository>(),
    ),
  );
  getIt.registerFactory<WorkoutViewModel>(
    () => WorkoutViewModel(
      getIt<WorkoutRepository>(),
      getIt<ExerciseRepository>(),
    ),
  );
}
