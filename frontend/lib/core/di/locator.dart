import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../network/auth_token_ref.dart';
import '../storage/token_storage.dart';
import '../../modules/auth/repositories/auth_repository.dart';
import '../../modules/masters/repositories/master_repository.dart';
import '../../modules/plans/repositories/plan_repository.dart';
import '../../modules/settings/repositories/site_settings_repository.dart';

final getIt = GetIt.instance;

PlanRepository getPlanRepository() => getIt<PlanRepository>();

Future<void> setupLocator() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  getIt.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(),
  );

  getIt.registerSingleton<AuthTokenRef>(AuthTokenRef());

  getIt.registerLazySingleton<TokenStorage>(
    () => TokenStorage(
      secure: getIt<FlutterSecureStorage>(),
      prefs: getIt<SharedPreferences>(),
    ),
  );

  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = getIt<AuthTokenRef>().value;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    return dio;
  });

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(dio: getIt<Dio>()),
  );
  getIt.registerLazySingleton<MasterRepository>(
    () => MasterRepository(dio: getIt<Dio>()),
  );
  getIt.registerLazySingleton<SiteSettingsRepository>(
    () => SiteSettingsRepository(dio: getIt<Dio>()),
  );
  getIt.registerLazySingleton<PlanRepository>(
    () => PlanRepository(dio: getIt<Dio>()),
  );
}
