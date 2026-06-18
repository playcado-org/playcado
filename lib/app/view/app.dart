import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:playcado/app_router/app_router.dart';
import 'package:playcado/auth/bloc/auth_bloc.dart';
import 'package:playcado/auth_repository/auth_repository.dart';
import 'package:playcado/cast/services/cast_device_service.dart';
import 'package:playcado/core/bootstrap.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/downloads/bloc/downloads_bloc.dart';
import 'package:playcado/downloads_repository/downloads_repository.dart';
import 'package:playcado/l10n/app_localizations.dart';
import 'package:playcado/libraries/bloc/libraries_bloc.dart';
import 'package:playcado/media/data/demo_remote_data_source.dart';
import 'package:playcado/media/data/jellyfin_remote_data_source.dart';
import 'package:playcado/media/repositories/library_repository.dart';
import 'package:playcado/onboarding/bloc/onboarding_cubit.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/player/repositories/player_tracker.dart';
import 'package:playcado/player/services/cast_player_service.dart';
import 'package:playcado/player/services/local_player_service.dart';
import 'package:playcado/search/repositories/search_repository.dart';
import 'package:playcado/services/media_url/demo_url_service.dart';
import 'package:playcado/services/media_url/jellyfin_url_service.dart';
import 'package:playcado/services/media_url/media_url_service.dart';
import 'package:playcado/services/preferences_service.dart';
import 'package:playcado/services/secure_storage_service.dart';
import 'package:playcado/theme/app_theme.dart';
import 'package:playcado/theme/bloc/theme_bloc.dart';

class App extends StatelessWidget {
  const App({required this.config, super.key});

  final BootstrapConfig config;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PreferencesService>.value(
          value: config.preferencesService,
        ),
        RepositoryProvider<AuthRepository>.value(value: config.authRepository),
        RepositoryProvider<CastDeviceService>.value(
          value: config.castDeviceService,
        ),
        RepositoryProvider<LocalPlayerService>.value(
          value: config.localPlayerService,
        ),
        RepositoryProvider<CastPlayerService>.value(
          value: config.castPlayerService,
        ),
        RepositoryProvider<SecureStorageService>.value(
          value: config.secureStorageService,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => OnboardingCubit(
              preferencesService: config.preferencesService,
              isFirstRun: config.isFirstRun,
            ),
          ),
          BlocProvider(
            create: (context) => ThemeBloc(
              preferencesService: config.preferencesService,
              initialColor: config.initialThemeColor,
            ),
          ),
          BlocProvider(
            create: (context) {
              return AuthBloc(
                authRepository: context.read<AuthRepository>(),
                initialUser: config.initialUser,
              );
            },
          ),
        ],
        child: BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (previous, current) =>
              previous.isDemoMode != current.isDemoMode ||
              previous.user.value?.id != current.user.value?.id,
          builder: (context, state) {
            final mediaUrlService = state.isDemoMode
                ? DemoUrlService()
                : JellyfinUrlService(config.jellyfinClientService);

            final remoteDataSource = state.isDemoMode
                ? DemoRemoteDataSource()
                : JellyfinRemoteDataSource(
                    clientManager: config.jellyfinClientService,
                  );

            return MultiRepositoryProvider(
              key: ValueKey('${state.isDemoMode}_${state.user.value?.id}'),
              providers: [
                RepositoryProvider<LibraryRepository>(
                  create: (context) =>
                      LibraryRepository(dataSource: remoteDataSource),
                ),
                RepositoryProvider<PlayerTracker>(
                  create: (context) =>
                      PlayerTracker(dataSource: remoteDataSource),
                ),
                RepositoryProvider<SearchRepository>(
                  create: (context) =>
                      SearchRepository(dataSource: remoteDataSource),
                ),
                RepositoryProvider<DownloadsRepository>(
                  create: (context) =>
                      DownloadsRepository(urlGenerator: mediaUrlService),
                  dispose: (repo) => repo.dispose(),
                ),
                RepositoryProvider<MediaUrlService>.value(
                  value: mediaUrlService,
                ),
              ],
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (context) => DownloadsBloc(
                      repository: context.read<DownloadsRepository>(),
                    ),
                  ),
                  BlocProvider(
                    create: (context) => PlayerBloc(
                      localService: context.read<LocalPlayerService>(),
                      castPlayerService: context.read<CastPlayerService>(),
                      castDeviceService: context.read<CastDeviceService>(),
                      playerTracker: context.read<PlayerTracker>(),
                      urlGenerator: context.read<MediaUrlService>(),
                      dataSource: remoteDataSource,
                      jellyfinClientService: config.jellyfinClientService,
                    ),
                  ),
                  BlocProvider(
                    create: (context) => LibrariesBloc(
                      libraryRepository: context.read<LibraryRepository>(),
                    )..add(LibrariesLibariesFetched()),
                  ),
                ],
                child: const AppView(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(
      authBloc: context.read<AuthBloc>(),
      onboardingCubit: context.read<OnboardingCubit>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return MaterialApp.router(
          onGenerateTitle: (context) => context.l10n.playcado,
          theme: AppTheme.light(seedColor: state.themeColor),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          darkTheme: AppTheme.dark(seedColor: state.themeColor),
          themeMode: ThemeMode.dark,
          routerConfig: _appRouter.router,
        );
      },
    );
  }
}
