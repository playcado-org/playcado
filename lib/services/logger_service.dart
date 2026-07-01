import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:playcado/core/secrets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class LoggerService {
  static final Logger _preferencesServiceLogger = Logger('AppPrefs');
  static final Logger _authRepositoryLogger = Logger('AuthRepo');
  static final Logger _castDeviceServiceLogger = Logger('CastDeviceService');
  static final Logger _playerTrackerRepositoryLogger = Logger(
    'PlayerTrackerRepo',
  );
  static final Logger _mediaBlocLogger = Logger('MediaBloc');
  static final Logger _mediaRepositoryLogger = Logger('MediaRepo');
  static final Logger _homeScreenLogger = Logger('HomeScreen');
  static final Logger _downloadsLogger = Logger('Downloads');
  static final Logger _playerLogger = Logger('Player');
  static final Logger _systemLogger = Logger('System');
  static final Logger _blocLogger = Logger('Bloc');
  static final Logger _secureStorageLogger = Logger('SecureStore');
  static final Logger _uiLogger = Logger('UI');

  static void initializeLogging() {
    // Enable hierarchical logging to allow distinct control if needed,
    // but primarily to reset the root logger cleanly.
    hierarchicalLoggingEnabled = true;
    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;

    // Remove any existing listeners (fixes duplicate logs on hot restart)
    Logger.root.clearListeners();

    Logger.root.onRecord.listen((record) {
      final message =
          '[Domain: ${record.loggerName}] [Level: ${record.level.name}] ${record.message}';

      if (record.error != null) {
        debugPrint('$message\nError: ${record.error}');
        if (record.stackTrace != null) {
          debugPrint('Stack: ${record.stackTrace}');
        }
      } else {
        debugPrint(message);
      }

      if (Secrets.isSentryEnabled) {
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: record.message,
            category: record.loggerName,
            level: _mapSentryLevel(record.level),
          ),
        );
      }
    });
  }

  static SentryLevel _mapSentryLevel(Level level) {
    if (level == Level.SEVERE) return SentryLevel.error;
    if (level == Level.WARNING) return SentryLevel.warning;
    if (level == Level.INFO) return SentryLevel.info;
    return SentryLevel.debug;
  }

  static Logger get preferencesService => _preferencesServiceLogger;
  static Logger get auth => _authRepositoryLogger;
  static Logger get castDeviceService => _castDeviceServiceLogger;
  static Logger get playerTracker => _playerTrackerRepositoryLogger;
  static Logger get media => _mediaBlocLogger;
  static Logger get api => _mediaRepositoryLogger;
  static Logger get home => _homeScreenLogger;
  static Logger get downloads => _downloadsLogger;
  static Logger get player => _playerLogger;
  static Logger get system => _systemLogger;
  static Logger get bloc => _blocLogger;
  static Logger get secureStorage => _secureStorageLogger;
  static Logger get ui => _uiLogger;
}
