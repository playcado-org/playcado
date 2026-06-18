import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:playcado/cast/services/cast_device_service.dart';
import 'package:playcado/downloads_repository/downloads_repository.dart';
import 'package:playcado/player/models/playable_media.dart';
import 'package:playcado/player/services/cast_player_service.dart';
import 'package:playcado/services/preferences_service.dart';
import 'package:playcado/services/secure_storage_service.dart';

part 'dev_tools_event.dart';
part 'dev_tools_state.dart';

class DevToolsBloc extends Bloc<DevToolsEvent, DevToolsState> {
  DevToolsBloc({
    required CastDeviceService castDeviceService,
    required CastPlayerService castPlayerService,
    required DownloadsRepository downloadsRepository,
    required PreferencesService preferencesService,
    required SecureStorageService secureStorage,
  }) : _castDeviceService = castDeviceService,
       _castPlayerService = castPlayerService,
       _downloadsRepository = downloadsRepository,
       _preferencesService = preferencesService,
       _secureStorage = secureStorage,
       super(const DevToolsState()) {
    on<DevToolsCastSessionUpdated>(_onCastSessionUpdated);
    on<DevToolsCastTestVideoRequested>(_onCastTestVideo);
    on<DevToolsClearDownloadsDataRequested>(_onClearDownloadsData);
    on<DevToolsClearPreferencesServiceRequested>(_onClearPreferencesService);
    on<DevToolsClearSecureStorageRequested>(_onClearSecureStorage);
    on<DevToolsDisconnectCastRequested>(_onDisconnectCast);
    on<DevToolsInitialized>(_onInitialized);
  }

  final CastDeviceService _castDeviceService;
  final CastPlayerService _castPlayerService;
  StreamSubscription<GoogleCastSession?>? _castSubscription;
  final DownloadsRepository _downloadsRepository;
  final PreferencesService _preferencesService;
  final SecureStorageService _secureStorage;

  @override
  Future<void> close() {
    unawaited(_castSubscription?.cancel());
    return super.close();
  }

  void _onCastSessionUpdated(
    DevToolsCastSessionUpdated event,
    Emitter<DevToolsState> emit,
  ) {
    emit(state.copyWith(isCastConnected: event.isConnected));
  }

  Future<void> _onCastTestVideo(
    DevToolsCastTestVideoRequested event,
    Emitter<DevToolsState> emit,
  ) async {
    const testUrl =
        'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

    try {
      await _castPlayerService.load(
        const PlayableMedia(
          id: 'test',
          title: 'TEST VIDEO (Big Buck Bunny)',
          streamUrl: testUrl,
          posterUrl:
              'https://upload.wikimedia.org/wikipedia/commons/7/70/Big.Buck.Bunny.-.Opening.Screen.png',
        ),
      );
      emit(
        state.copyWith(
          status: DevToolsStatus.success,
          message: 'Sending video to Cast device...',
        ),
      );
    } on Exception catch (_) {
      emit(
        state.copyWith(
          status: DevToolsStatus.error,
          message: 'Failed to cast test video',
        ),
      );
    }
  }

  Future<void> _onClearDownloadsData(
    DevToolsClearDownloadsDataRequested event,
    Emitter<DevToolsState> emit,
  ) async {
    try {
      await _downloadsRepository.clearAll();
      emit(
        state.copyWith(
          status: DevToolsStatus.success,
          message: 'Downloads Meta Cleared',
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: DevToolsStatus.error,
          message: 'Error clearing downloads: $e',
        ),
      );
    }
  }

  Future<void> _onClearPreferencesService(
    DevToolsClearPreferencesServiceRequested event,
    Emitter<DevToolsState> emit,
  ) async {
    try {
      await _preferencesService.resetAll();
      emit(
        state.copyWith(
          status: DevToolsStatus.success,
          message: 'App Preferences Reset',
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: DevToolsStatus.error,
          message: 'Error reseting app preferences: $e',
        ),
      );
    }
  }

  Future<void> _onClearSecureStorage(
    DevToolsClearSecureStorageRequested event,
    Emitter<DevToolsState> emit,
  ) async {
    try {
      await _secureStorage.deleteAll();
      emit(
        state.copyWith(
          status: DevToolsStatus.success,
          message: 'Secure Storage Cleared',
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: DevToolsStatus.error,
          message: 'Error clearing storage: $e',
        ),
      );
    }
  }

  Future<void> _onDisconnectCast(
    DevToolsDisconnectCastRequested event,
    Emitter<DevToolsState> emit,
  ) async {
    await _castDeviceService.disconnect();
  }

  void _onInitialized(DevToolsInitialized event, Emitter<DevToolsState> emit) {
    final isConnected = _castDeviceService.isConnected;
    emit(state.copyWith(isCastConnected: isConnected));

    unawaited(_castSubscription?.cancel());
    _castSubscription = _castDeviceService.currentSessionStream.listen((_) {
      final connected = _castDeviceService.isConnected;
      add(DevToolsCastSessionUpdated(isConnected: connected));
    });
  }
}
