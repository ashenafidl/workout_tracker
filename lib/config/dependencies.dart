import "package:get_it/get_it.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:workout_tracker/data/models/workout_session_args.dart";
import "package:workout_tracker/data/repositories/exercise_repo.dart";
import "package:workout_tracker/data/repositories/program_repo.dart";
import "package:workout_tracker/data/repositories/session_repo.dart";
import "package:workout_tracker/data/repositories/workout_repo.dart";
import "package:workout_tracker/data/services/shared_preference_service.dart";
import "package:workout_tracker/database/database.dart";
import "package:workout_tracker/ui/exercises/view_models/exercise_form_view_model.dart";
import "package:workout_tracker/ui/exercises/view_models/exercise_list_view_model.dart";
import "package:workout_tracker/ui/history/view_models/history_view_model.dart";
import "package:workout_tracker/ui/home/view_models/home_view_model.dart";
import "package:workout_tracker/ui/more/view_models/more_view_model.dart";
import "package:workout_tracker/ui/programs/view_models/program_detail_view_model.dart";
import "package:workout_tracker/ui/programs/view_models/programs_view_model.dart";
import "package:workout_tracker/ui/programs/view_models/workout_view_model.dart";
import "package:workout_tracker/ui/session/view_models/workout_session_view_model.dart";

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // DB
  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);

  // Shared Preference
  final prefs = await SharedPreferences.getInstance();

  // Services
  getIt.registerSingleton<SharedPreferenceService>(
    SharedPreferenceService(prefs),
  );

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
  getIt.registerLazySingleton<SessionRepository>(
    () => SessionRepository(getIt<AppDatabase>()),
  );

  // ViewModels
  getIt.registerFactory<MoreViewModel>(
    () =>
        MoreViewModel(getIt<ExerciseRepo>(), getIt<SharedPreferenceService>()),
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
  getIt.registerLazySingleton<ProgramDetailViewModel>(
    () => ProgramDetailViewModel(
      getIt<ProgramRepo>(),
      getIt<WorkoutRepo>(),
      getIt<SharedPreferenceService>(),
    ),
  );
  getIt.registerFactory<WorkoutViewModel>(
    () => WorkoutViewModel(getIt<WorkoutRepo>(), getIt<ExerciseRepo>()),
  );
  getIt.registerLazySingleton<HomeViewModel>(
    () => HomeViewModel(getIt<ProgramRepo>(), getIt<WorkoutRepo>()),
  );
  getIt.registerLazySingleton<HistoryViewModel>(
    () => HistoryViewModel(getIt<SessionRepository>()),
  );
  getIt.registerFactoryParam<
    WorkoutSessionViewModel,
    WorkoutSessionArgs,
    AppDatabase?
  >(
    (args, db) => WorkoutSessionViewModel(
      args: args,
      sharedPreferenceService: getIt<SharedPreferenceService>(),
      database: db ?? getIt<AppDatabase>(),
    ),
  );
}
