import 'dart:async';
import 'dart:io';

import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:playcado/services/logger_service.dart';

/// Manages Google Cast device discovery, connection, and session lifecycle.
///
/// Wraps [GoogleCastSessionManager] and [GoogleCastDiscoveryManager] to
/// provide a simplified interface for connecting to and disconnecting from
/// Chromecast devices. Only supported on iOS and Android.
class CastDeviceManager {
  CastDeviceManager();

  final GoogleCastSessionManagerPlatformInterface _sessionManager =
      GoogleCastSessionManager.instance;
  final GoogleCastDiscoveryManagerPlatformInterface _discoveryManager =
      GoogleCastDiscoveryManager.instance;

  bool _isInitialized = false;

  /// Whether the current platform supports Google Cast.
  bool get _isSupportedPlatform => Platform.isIOS || Platform.isAndroid;

  /// Stream of discovered Cast devices.
  Stream<List<GoogleCastDevice>> get devicesStream =>
      _discoveryManager.devicesStream;

  /// Stream of the current Cast session, emitting null when disconnected.
  Stream<GoogleCastSession?> get currentSessionStream =>
      _sessionManager.currentSessionStream;

  /// The current active Cast session, or null if not connected.
  GoogleCastSession? get currentSession => _sessionManager.currentSession;

  /// Whether a Cast device is currently connected.
  bool get isConnected =>
      _sessionManager.connectionState == GoogleCastConnectState.connected;

  /// Initializes the Cast context and starts device discovery.
  ///
  /// Sets up platform-specific Cast options (iOS or Android), starts scanning
  /// for nearby devices, and begins logging session and discovery events.
  /// Safe to call multiple times — only initializes once.
  Future<void> initialize() async {
    if (!_isSupportedPlatform || _isInitialized) return;

    LoggerService.castDeviceManager.info('Initializing Google Cast Options');
    const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;

    GoogleCastOptions? options;
    if (Platform.isIOS) {
      options = IOSGoogleCastOptions(
        GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId),
      );
    } else if (Platform.isAndroid) {
      options = GoogleCastOptionsAndroid(appId: appId);
    }

    if (options != null) {
      await GoogleCastContext.instance.setSharedInstanceWithOptions(options);
    }

    _isInitialized = true;
    unawaited(_discoveryManager.startDiscovery());

    currentSessionStream.listen((session) {
      LoggerService.castDeviceManager.info(
        'Cast Session: '
        'ConnectionState:${session?.connectionState}, '
        'Device:${session?.device?.friendlyName}, '
        'SessionID:${session?.sessionID}, '
        'Muted:${session?.currentDeviceMuted}, '
        'Volume:${session?.currentDeviceVolume}, '
        'Status:${session?.deviceStatusText}',
      );
    });

    devicesStream.listen((devices) {
      LoggerService.castDeviceManager.info(
        'Discovered devices: ${devices.length}',
      );
    });
  }

  /// Connects to the given [device] and starts a Cast session.
  Future<void> connect(GoogleCastDevice device) async {
    if (!_isSupportedPlatform) return;
    LoggerService.castDeviceManager.info(
      'Connecting to Cast device: ${device.friendlyName}',
    );
    try {
      await _sessionManager.startSessionWithDevice(device);
    } on Exception catch (e, stack) {
      LoggerService.castDeviceManager.severe(
        'Failed to connect to Cast device',
        e,
        stack,
      );
    }
  }

  /// Disconnects the current Cast session and stops casting.
  Future<void> disconnect() async {
    if (!_isSupportedPlatform) return;
    LoggerService.castDeviceManager.info('Disconnecting from Cast device...');
    try {
      await _sessionManager.endSessionAndStopCasting();
    } on Exception catch (e, stack) {
      LoggerService.castDeviceManager.severe(
        'Failed to disconnect Cast',
        e,
        stack,
      );
    }
  }

  /// Waits until a Cast device is connected, with an optional [timeout].
  ///
  /// Returns `true` if a session was established within [timeout],
  /// `false` if the timeout was reached or no connection was made.
  Future<bool> waitUntilConnected({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (isConnected) return true;

    try {
      await currentSessionStream
          .firstWhere(
            (session) =>
                session?.connectionState == GoogleCastConnectState.connected,
          )
          .timeout(timeout);
      return true;
    } on Exception catch (e) {
      LoggerService.castDeviceManager.warning(
        'Wait for connection timed out: $e',
      );
      return false;
    }
  }
}
