import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:playcado/app/view/app.dart';
import 'package:playcado/auth_repository/auth_repository.dart';
import 'package:playcado/cast/cast_device_manager.dart';
import 'package:playcado/core/app_bloc_observer.dart';
import 'package:playcado/core/secrets.dart';
import 'package:playcado/media/data/jellyfin_remote_data_source.dart';
import 'package:playcado/media/repos/library_repository.dart';
import 'package:playcado/player/services/local_playback_service.dart';
import 'package:playcado/player/services/cast_playback_service.dart';
import 'package:playcado/player/repos/player_tracker.dart';
import 'package:playcado/search/repos/search_repository.dart';
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
    required this.jellyfinClientService,
    required this.authRepository,
    required this.libraryRepository,
    required this.playerTracker,
    required this.searchRepository,
    required this.mediaUrlService,
    required this.castDeviceManager,
    required this.localPlayerEngine,
    required this.castPlayerEngine,
    required this.preferencesService,
    required this.secureStorageService,
    required this.isFirstRun,
    this.initialUser,
    this.initialThemeColor,
  });

  final JellyfinClientService jellyfinClientService;
  final AuthRepository authRepository;
  final LibraryRepository libraryRepository;
  final PlayerTracker playerTracker;
  final SearchRepository searchRepository;
  final MediaUrlService mediaUrlService;
  final CastDeviceManager castDeviceManager;
  final LocalPlaybackService localPlayerEngine;
  final CastPlaybackService castPlayerEngine;
  final PreferencesService preferencesService;
  final SecureStorageService secureStorageService;
  final bool isFirstRun;
  final User? initialUser;
  final Color? initialThemeColor;
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
  final playerTracker = PlayerTracker(dataSource: remoteDataSource);
  final searchRepository = SearchRepository(dataSource: remoteDataSource);

  final castDeviceManager = CastDeviceManager();
  final localPlayerEngine = LocalPlaybackService();
  final castPlayerEngine = CastPlaybackService();
  final preferencesService = PreferencesService();

  // Initialize Cast service early
  await castDeviceManager.initialize();

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
    jellyfinClientService: jellyfinClientService,
    authRepository: authRepository,
    libraryRepository: libraryRepository,
    playerTracker: playerTracker,
    searchRepository: searchRepository,
    mediaUrlService: mediaUrlService,
    castDeviceManager: castDeviceManager,
    localPlayerEngine: localPlayerEngine,
    castPlayerEngine: castPlayerEngine,
    preferencesService: preferencesService,
    secureStorageService: secureStorage,
    isFirstRun: isFirstRun,
    initialUser: initialUser,
    initialThemeColor: savedThemeColor,
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
