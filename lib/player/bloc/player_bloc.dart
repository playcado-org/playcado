import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:playcado/cast/services/cast_device_service.dart';
import 'package:playcado/media/data/media_remote_data_source.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/player/models/playable_media.dart';
import 'package:playcado/player/repositories/player_tracker_repository.dart';
import 'package:playcado/player/services/cast_player_service.dart';
import 'package:playcado/player/services/local_player_service.dart';
import 'package:playcado/player/services/player_service.dart';
import 'package:playcado/services/jellyfin_client_service.dart';
import 'package:playcado/services/logger_service.dart';
import 'package:playcado/services/media_url/media_url_service.dart';

part 'player_event.dart';
part 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  PlayerBloc({
    required CastDeviceService castDeviceService,
    required CastPlayerService castPlayerService,
    required MediaRemoteDataSource dataSource,
    required JellyfinClientService jellyfinClientService,
    required LocalPlayerService localService,
    required PlayerTrackerRepository playerTracker,
    required MediaUrlService urlGenerator,
  }) : _castDeviceService = castDeviceService,
       _castPlayerService = castPlayerService,
       _dataSource = dataSource,
       _jellyfinClientService = jellyfinClientService,
       _localService = localService,
       _playerTracker = playerTracker,
       _urlGenerator = urlGenerator,
       super(const PlayerState()) {
    on<PlayerCastRequested>(_onCastRequested);
    on<PlayerPauseRequested>(_onPauseRequested);
    on<PlayerPlayRequested>(_onPlayRequested);
    on<PlayerResumeRequested>(_onResumeRequested);
    on<PlayerSeekRequested>(_onSeekRequested);
    on<PlayerSkipIntroRequested>(_onSkipIntroRequested);
    on<PlayerStopRequested>(_onStopRequested);
    on<PlayerTogglePlayPauseRequested>(_onTogglePlayPause);
    on<PlayerTrackSelected>(_onTrackSelected);
    on<ServiceStateUpdated>(_onInternalServiceStateUpdated);

    _initCastListeners();
  }

  PlayerService? _activeService;
  final CastDeviceService _castDeviceService;
  final CastPlayerService _castPlayerService;
  StreamSubscription<GoogleCastSession?>? _castSessionSub;
  final MediaRemoteDataSource _dataSource;
  bool _isLocalMedia = false;
  final JellyfinClientService _jellyfinClientService;
  DateTime _lastProgressReport = DateTime.now();
  final LocalPlayerService _localService;
  final PlayerTrackerRepository _playerTracker;
  StreamSubscription<PlayerServiceState>? _serviceSub;
  final MediaUrlService _urlGenerator;
  bool _wasCasting = false;

  @override
  Future<void> close() {
    unawaited(_serviceSub?.cancel());
    unawaited(_castSessionSub?.cancel());
    if (_activeService != null) {
      unawaited(_activeService!.stop());
    }
    return super.close();
  }

  Future<PlayableMedia> _buildPlayableMedia(
    MediaItem item, {
    bool forCast = false,
    String? localPath,
  }) async {
    final startTicks = item.playbackPositionTicks ?? 0;
    final startPosition = startTicks > 0
        ? Duration(microseconds: startTicks ~/ 10)
        : Duration.zero;

    if (forCast) {
      String? mediaSourceId = item.mediaSourceId;
      if (mediaSourceId == null) {
        final userId = await _dataSource.getCurrentUserId();
        if (userId != null) {
          final items = await _dataSource.fetchItems(
            userId: userId,
            ids: [item.id],
            fields: [ItemFields.mediaSources],
          );
          if (items.isNotEmpty) {
            mediaSourceId = items.first.mediaSourceId;
          }
        }
      }

      final streamUrl = _urlGenerator.generateTranscodeUrl(
        itemId: item.id,
        mediaSourceId: mediaSourceId ?? item.id,
      );

      return PlayableMedia(
        id: item.id,
        title: item.name,
        subtitle: item.displaySubtitle,
        streamUrl: streamUrl,
        posterUrl: _urlGenerator.getImageUrl(item.id),
        startPosition: startPosition,
      );
    }

    String source;
    Map<String, String>? headers;

    if (localPath != null) {
      source = localPath;
    } else {
      source = _urlGenerator.getStreamUrl(item.id);
      headers = {
        'X-Emby-Authorization':
            'MediaBrowser Client="Playcado", '
            'Device="Flutter", '
            'DeviceId="${_jellyfinClientService.deviceId}", '
            'Version="1.0.0", '
            'Token="${_jellyfinClientService.accessToken}"',
      };
    }

    return PlayableMedia(
      id: item.id,
      title: item.name,
      subtitle: item.displaySubtitle,
      streamUrl: source,
      posterUrl: _urlGenerator.getImageUrl(item.id),
      httpHeaders: headers,
      startPosition: startPosition,
    );
  }

  PlayerStatus _determineStatus(PlayerServiceState serviceState) {
    if (state.status == PlayerStatus.loading) {
      if (!serviceState.isBuffering && serviceState.position > Duration.zero) {
        return PlayerStatus.playing;
      }
      return PlayerStatus.loading;
    }
    if (serviceState.isCompleted) {
      return PlayerStatus.stopped;
    }
    if (serviceState.isPlaying) {
      return PlayerStatus.playing;
    }
    if (state.status == PlayerStatus.playing && !serviceState.isPlaying) {
      return PlayerStatus.paused;
    }
    return state.status;
  }

  Future<void> _handleProgressReporting(Duration position) async {
    if (_isLocalMedia ||
        state.mediaItem == null ||
        state.isCasting ||
        state.status != PlayerStatus.playing) {
      return;
    }

    if (DateTime.now().difference(_lastProgressReport).inSeconds > 10) {
      _lastProgressReport = DateTime.now();
      final ticks = position.inMicroseconds * 10;
      await _playerTracker.reportPlaybackProgress(
        itemId: state.mediaItem!.id,
        positionTicks: ticks,
      );
    }
  }

  void _initCastListeners() {
    _castSessionSub = _castDeviceService.currentSessionStream.listen((_) {
      final connected = _castDeviceService.isConnected;
      if (!connected && _wasCasting) {
        add(PlayerStopRequested());
      }
      _wasCasting = connected;
    });
  }

  Future<void> _onCastRequested(
    PlayerCastRequested event,
    Emitter<PlayerState> emit,
  ) async {
    LoggerService.player.info('Cast requested for ${event.item.name}');

    if (_activeService != null && !state.isCasting) {
      await _activeService!.stop();
    }

    emit(
      state.copyWith(
        status: PlayerStatus.loading,
        mediaItem: event.item,
        isCasting: true,
        isLocalMedia: false,
      ),
    );
    _isLocalMedia = false;

    try {
      if (!_castDeviceService.isConnected) {
        final connected = await _castDeviceService.waitUntilConnected();
        if (!connected) {
          emit(state.copyWith(status: PlayerStatus.error));
          return;
        }
      }

      final playableMedia = await _buildPlayableMedia(
        event.item,
        forCast: true,
      );
      _activeService = _castPlayerService;
      _subscribeToService(_castPlayerService);
      await _castPlayerService.load(playableMedia);
    } on Exception catch (e) {
      LoggerService.player.severe('Failed to cast media', e);
      emit(state.copyWith(status: PlayerStatus.error));
    }
  }

  void _onInternalServiceStateUpdated(
    ServiceStateUpdated event,
    Emitter<PlayerState> emit,
  ) {
    if (_activeService == null) return;
    final serviceState = event.serviceState;
    final item = state.mediaItem;
    var showSkip = false;

    if (item != null) {
      final introStart = item.introStartTicks;
      final introEnd = item.introEndTicks;
      if (introStart != null && introEnd != null) {
        final currentTicks = serviceState.position.inMicroseconds * 10;
        if (currentTicks >= introStart && currentTicks < introEnd) {
          showSkip = true;
        }
      }
    }

    final newStatus = _determineStatus(serviceState);

    emit(
      state.copyWith(
        position: serviceState.position,
        duration: serviceState.duration,
        isBuffering: serviceState.isBuffering,
        showSkipIntro: showSkip,
        status: newStatus,
        playerView: _activeService?.playerView,
      ),
    );

    if (newStatus == PlayerStatus.playing) {
      _handleProgressReporting(serviceState.position);
    }
  }

  Future<void> _onPauseRequested(
    PlayerPauseRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (_activeService == null) return;
    await _activeService!.pause();
    emit(state.copyWith(status: PlayerStatus.paused));
  }

  Future<void> _onPlayRequested(
    PlayerPlayRequested event,
    Emitter<PlayerState> emit,
  ) async {
    LoggerService.player.info('Play requested for ${event.item.name}');

    final useCast = _castDeviceService.isConnected;

    if (useCast) {
      emit(
        state.copyWith(
          status: PlayerStatus.loading,
          mediaItem: event.item,
          isCasting: true,
          isLocalMedia: false,
        ),
      );
      _isLocalMedia = false;

      try {
        final playableMedia = await _buildPlayableMedia(
          event.item,
          forCast: true,
        );
        _activeService = _castPlayerService;
        _subscribeToService(_castPlayerService);
        await _castPlayerService.load(playableMedia);
      } on Exception catch (e) {
        LoggerService.player.severe('Failed to start cast playback', e);
        emit(state.copyWith(status: PlayerStatus.error));
      }
      return;
    }

    emit(
      state.copyWith(
        status: PlayerStatus.loading,
        mediaItem: event.item,
        localPath: event.localPath,
        isLocalMedia: event.localPath != null,
        isCasting: false,
      ),
    );
    _isLocalMedia = event.localPath != null;

    if (event.localPath == null) {
      unawaited(_playerTracker.reportPlaybackStart(event.item.id));
    }

    try {
      final playableMedia = await _buildPlayableMedia(
        event.item,
        localPath: event.localPath,
        forCast: false,
      );
      _activeService = _localService;
      _subscribeToService(_localService);
      await _localService.load(playableMedia);
    } on Exception catch (e) {
      LoggerService.player.severe('Failed to play media', e);
      emit(state.copyWith(status: PlayerStatus.error));
    }
  }

  Future<void> _onResumeRequested(
    PlayerResumeRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (_activeService == null) return;
    await _activeService!.play();
    emit(state.copyWith(status: PlayerStatus.playing));
  }

  Future<void> _onSeekRequested(
    PlayerSeekRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (_activeService == null) return;
    await _activeService!.seek(event.position);
  }

  Future<void> _onSkipIntroRequested(
    PlayerSkipIntroRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (_activeService == null) return;
    final item = state.mediaItem;
    final introEndTicks = item?.introEndTicks;
    if (item != null && introEndTicks != null) {
      final endDuration = Duration(microseconds: introEndTicks ~/ 10);
      await _activeService!.seek(endDuration);
      emit(state.copyWith(showSkipIntro: false));
    }
  }

  Future<void> _onStopRequested(
    PlayerStopRequested event,
    Emitter<PlayerState> emit,
  ) async {
    final finalPosition = state.position;
    final item = state.mediaItem;

    if (_activeService != null) {
      await _activeService!.stop();
      _activeService = null;
    }

    await _serviceSub?.cancel();
    _serviceSub = null;

    if (item != null && !_isLocalMedia) {
      await _playerTracker.reportPlaybackStopped(
        itemId: item.id,
        positionTicks: finalPosition.inMicroseconds * 10,
      );
    }

    emit(
      state.copyWith(
        status: PlayerStatus.stopped,
        position: finalPosition,
        showSkipIntro: false,
        isCasting: false,
        playerView: null,
      ),
    );
  }

  Future<void> _onTogglePlayPause(
    PlayerTogglePlayPauseRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (_activeService == null) return;
    if (state.status == PlayerStatus.playing) {
      add(PlayerPauseRequested());
    } else {
      add(PlayerResumeRequested());
    }
  }

  Future<void> _onTrackSelected(
    PlayerTrackSelected event,
    Emitter<PlayerState> emit,
  ) async {
    if (_activeService == null) return;
    if (event.type == TrackType.audio) {
      await _activeService!.setAudioTrack(event.index);
    } else {
      await _activeService!.setSubtitleTrack(event.index);
    }
  }

  void _subscribeToService(PlayerService service) {
    _serviceSub?.cancel();
    _serviceSub = service.stateStream.listen((serviceState) {
      if (isClosed) return;
      add(ServiceStateUpdated(serviceState));
    });
  }
}
