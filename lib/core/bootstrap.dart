import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:playcado/app/view/app.dart';
import 'package:playcado/auth_repository/auth_repository.dart';
import 'package:playcado/cast/services/cast_device_service.dart';
import 'package:playcado/core/app_bloc_observer.dart';
import 'package:playcado/core/secrets.dart';
import 'package:playcado/media/data/jellyfin_remote_data_source.dart';
import 'package:playcado/media/repositories/library_repository.dart';
import 'package:playcado/player/repositories/player_tracker_repository.dart';
import 'package:playcado/player/services/cast_player_service.dart';
import 'package:playcado/player/services/local_player_service.dart';
import 'package:playcado/search/repositories/search_repository.dart';
import 'package:playcado/services/jellyfin_client_service.dart';
import 'package:playcado/services/logger_service.dart';
import 'package:playcado/services/media_url/jellyfin_url_service.dart';
import 'package:playcado/services/media_url/media_url_service.dart';
import 'package:playcado/services/preferences_service.dart';
import 'package:playcado/services/secure_storage_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Configuration data returned from bootstrap initialization.
class BootstrapConfig {
  const BootstrapConfig({
    required this.authRepository,
    required this.castDeviceService,
    required this.castPlayerService,
    this.initialThemeColor,
    this.initialUser,
    required this.isFirstRun,
    required this.jellyfinClientService,
    required this.libraryRepository,
    required this.localPlayerService,
    required this.mediaUrlService,
    required this.playerTracker,
    required this.preferencesService,
    required this.searchRepository,
    required this.secureStorageService,
  });

  final AuthRepository authRepository;
  final CastDeviceService castDeviceService;
  final CastPlayerService castPlayerService;
  final Color? initialThemeColor;
  final User? initialUser;
  final bool isFirstRun;
  final JellyfinClientService jellyfinClientService;
  final LibraryRepository libraryRepository;
  final LocalPlayerService localPlayerService;
  final MediaUrlService mediaUrlService;
  final PlayerTrackerRepository playerTracker;
  final PreferencesService preferencesService;
  final SearchRepository searchRepository;
  final SecureStorageService secureStorageService;
}

/// Bootstrap the application by initializing all required services,
/// dependencies, and running the app.
///
/// This follows the Very Good CLI bootstrap pattern where all initialization
/// is encapsulated and `runApp` is called internally.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MediaKit for video playback
  try {
    MediaKit.ensureInitialized();
  } catch (_) {
    // Already initialized (e.g. during hot-restart)
  }

  // Initialize logging service
  LoggerService.initializeLogging();
  LoggerService.system.info('App Starting...');

  // Set up BLoC observer for debugging
  Bloc.observer = AppBlocObserver();

  // Configure system UI
  await _configureSystemUI();

  // Initialize all services and repositories
  final config = await _initializeServices();

  final app = App(config: config);

  final shouldInitializeSentry = Secrets.isSentryEnabled;

  if (shouldInitializeSentry) {
    LoggerService.system.info('Starting app with Sentry');
    await SentryFlutter.init((options) {
      options
        ..dsn = Secrets.sentryDsn
        ..sendDefaultPii = false
        ..enableLogs = false
        ..tracesSampleRate = 0.2;
      options.replay.sessionSampleRate = 0.0;
      options.replay.onErrorSampleRate = 0.0;
    }, appRunner: () => runApp(SentryWidget(child: app)));
  } else {
    LoggerService.system.warning(
      'Sentry disabled: SENTRY_DSN not provided in environment',
    );
    runApp(app);
  }
}

/// Initialize all core services and repositories.
Future<BootstrapConfig> _initializeServices() async {
  final jellyfinClientService = JellyfinClientService();
  final secureStorage = SecureStorageService();
  final authRepository = AuthRepository(
    jellyfinClient: jellyfinClientService,
    secureStorage: secureStorage,
  );
  final remoteDataSource = JellyfinRemoteDataSource(
    clientManager: jellyfinClientService,
  );

  final mediaUrlService = JellyfinUrlService(jellyfinClientService);

  final libraryRepository = LibraryRepository(dataSource: remoteDataSource);
  final playerTracker = PlayerTrackerRepository(dataSource: remoteDataSource);
  final searchRepository = SearchRepository(dataSource: remoteDataSource);

  final castDeviceService = CastDeviceService();
  final localPlayerService = LocalPlayerService();
  final castPlayerService = CastPlayerService();
  final preferencesService = PreferencesService();

  // Initialize Cast service early
  await castDeviceService.initialize();

  // Load app preferences
  final isFirstRun = await preferencesService.isFirstRun();
  final savedThemeColor = await preferencesService.getThemeColor();

  // Attempt auto-login if not first run
  final initialUser = await _attemptAutoLogin(
    isFirstRun: isFirstRun,
    authRepository: authRepository,
    jellyfinClientService: jellyfinClientService,
  );

  return BootstrapConfig(
    authRepository: authRepository,
    castDeviceService: castDeviceService,
    castPlayerService: castPlayerService,
    initialThemeColor: savedThemeColor,
    initialUser: initialUser,
    isFirstRun: isFirstRun,
    jellyfinClientService: jellyfinClientService,
    libraryRepository: libraryRepository,
    localPlayerService: localPlayerService,
    mediaUrlService: mediaUrlService,
    playerTracker: playerTracker,
    preferencesService: preferencesService,
    searchRepository: searchRepository,
    secureStorageService: secureStorage,
  );
}

/// Configure system UI settings.
Future<void> _configureSystemUI() async {
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

/// Attempt to auto-login the user if not first run.
/// Returns the initial user if successful, null otherwise.
Future<User?> _attemptAutoLogin({
  required bool isFirstRun,
  required AuthRepository authRepository,
  required JellyfinClientService jellyfinClientService,
}) async {
  if (isFirstRun) {
    return null;
  }

  try {
    final user = await authRepository.tryAutoLogin();
    if (user != null) {
      LoggerService.auth.info(
        'Auto-login pre-check successful for ${user.name}',
      );
    }
    return user;
  } on Exception catch (e, s) {
    LoggerService.auth.warning('Pre-run auto-login check failed', e, s);
    await authRepository.logout();
    return null;
  }
}
