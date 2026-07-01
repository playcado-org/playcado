import 'dart:async';
import 'dart:io';

import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:playcado/services/logger_service.dart';

class CastDeviceService {
  CastDeviceService();

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

    LoggerService.castDeviceService.info('[Cast: Initializing]');
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
      LoggerService.castDeviceService.info(
        '[Cast: SessionUpdate] [State: ${session?.connectionState}] [Device: ${session?.device?.friendlyName}] [SessionId: ${session?.sessionID}]',
      );
    });

    devicesStream.listen((devices) {
      LoggerService.castDeviceService.info(
        '[Cast: DevicesDiscovered] [Count: ${devices.length}]',
      );
    });
  }

  Future<void> connect(GoogleCastDevice device) async {
    if (!_isSupportedPlatform) return;
    LoggerService.castDeviceService.info(
      '[Cast: Connecting] [Device: ${device.friendlyName}]',
    );
    try {
      await _sessionManager.startSessionWithDevice(device);
    } on Exception catch (e, stack) {
      LoggerService.castDeviceService.severe(
        '[Cast: ConnectFailed] [Device: ${device.friendlyName}]',
        e,
        stack,
      );
    }
  }

  Future<void> disconnect() async {
    if (!_isSupportedPlatform) return;
    LoggerService.castDeviceService.info('[Cast: Disconnecting]');
    try {
      await _sessionManager.endSessionAndStopCasting();
    } on Exception catch (e, stack) {
      LoggerService.castDeviceService.severe(
        '[Cast: DisconnectFailed]',
        e,
        stack,
      );
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
    } on Exception {
      LoggerService.castDeviceService.warning('[Cast: ConnectionTimeout]');
      return false;
    }
  }
}
