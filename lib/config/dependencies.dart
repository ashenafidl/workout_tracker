import "package:get_it/get_it.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:workout_tracker/data/repositories/exercise_repo.dart";
import "package:workout_tracker/data/repositories/program_repo.dart";
import "package:workout_tracker/data/repositories/workout_repo.dart";
import "package:workout_tracker/data/services/settings_service.dart";
import "package:workout_tracker/database/database.dart";
import "package:workout_tracker/ui/exercises/view_models/exercise_form_view_model.dart";
import "package:workout_tracker/ui/exercises/view_models/exercise_list_view_model.dart";
import "package:workout_tracker/ui/home/view_models/home_view_model.dart";
import "package:workout_tracker/ui/more/view_models/more_view_model.dart";
import "package:workout_tracker/ui/programs/view_models/program_detail_view_model.dart";
import "package:workout_tracker/ui/programs/view_models/programs_view_model.dart";
import "package:workout_tracker/ui/programs/view_models/workout_view_model.dart";

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // DB
  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);

  // Shared Preference
  final prefs = await SharedPreferences.getInstance();

  // Services
  getIt.registerSingleton<SettingsService>(SettingsService(prefs));

  // Repositories
  getIt.registerLazySingleton<ExerciseRepo>(
    () => ExerciseRepo(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<ProgramRepo>(
    () => ProgramRepo(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<WorkoutRepo>(
    () => WorkoutRepo(getIt<AppDatabase>()),
  );

  // ViewModels
  getIt.registerFactory<MoreViewModel>(
    () => MoreViewModel(getIt<ExerciseRepo>(), getIt<SettingsService>()),
  );
  getIt.registerFactory<ExerciseListViewModel>(
    () => ExerciseListViewModel(getIt<ExerciseRepo>()),
  );
  getIt.registerFactory<ExerciseFormViewModel>(
    () => ExerciseFormViewModel(getIt<ExerciseRepo>()),
  );
  getIt.registerFactory<ProgramsViewModel>(
    () => ProgramsViewModel(getIt<ProgramRepo>()),
  );
  getIt.registerFactory<ProgramDetailViewModel>(
    () => ProgramDetailViewModel(getIt<ProgramRepo>(), getIt<WorkoutRepo>()),
  );
  getIt.registerFactory<WorkoutViewModel>(
    () => WorkoutViewModel(getIt<WorkoutRepo>(), getIt<ExerciseRepo>()),
  );
  getIt.registerFactory<HomeViewModel>(HomeViewModel.new);
}
