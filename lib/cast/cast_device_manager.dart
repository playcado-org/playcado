import 'dart:async';
import 'dart:io';

import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:playcado/services/logger_service.dart';

class CastDeviceManager {
  CastDeviceManager();

  final GoogleCastSessionManagerPlatformInterface _sessionManager =
      GoogleCastSessionManager.instance;
  final GoogleCastDiscoveryManagerPlatformInterface _discoveryManager =
      GoogleCastDiscoveryManager.instance;

  bool _isInitialized = false;

  bool get _isSupportedPlatform => Platform.isIOS || Platform.isAndroid;

  Stream<List<GoogleCastDevice>> get devicesStream =>
      _discoveryManager.devicesStream;

  Stream<GoogleCastSession?> get currentSessionStream =>
      _sessionManager.currentSessionStream;

  GoogleCastSession? get currentSession => _sessionManager.currentSession;

  bool get isConnected =>
      _sessionManager.connectionState == GoogleCastConnectState.connected;

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
      LoggerService.castDeviceManager.info('Discovered devices: ${devices.length}');
    });
  }

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

  Future<void> disconnect() async {
    if (!_isSupportedPlatform) return;
    LoggerService.castDeviceManager.info('Disconnecting from Cast device...');
    try {
      await _sessionManager.endSessionAndStopCasting();
    } on Exception catch (e, stack) {
      LoggerService.castDeviceManager.severe('Failed to disconnect Cast', e, stack);
    }
  }

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
      LoggerService.castDeviceManager.warning('Wait for connection timed out: $e');
      return false;
    }
  }
}
