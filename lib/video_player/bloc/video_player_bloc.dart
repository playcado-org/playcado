import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:playcado/cast/cast_device_manager.dart';
import 'package:playcado/media/data/media_remote_data_source.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/playback/engine/cast_playback_engine.dart';
import 'package:playcado/playback/engine/local_playback_engine.dart';
import 'package:playcado/playback/engine/playback_engine.dart';
import 'package:playcado/playback/models/playable_media.dart';
import 'package:playcado/playback/repos/playback_tracker.dart';
import 'package:playcado/services/jellyfin_client_service.dart';
import 'package:playcado/services/logger_service.dart';
import 'package:playcado/services/media_url/media_url_service.dart';

part 'video_player_event.dart';
part 'video_player_state.dart';

class _EngineStateUpdated extends VideoPlayerEvent {
  const _EngineStateUpdated(this.engineState);
  final PlaybackEngineState engineState;

  @override
  List<Object?> get props => [engineState];
}

class VideoPlayerBloc extends Bloc<VideoPlayerEvent, VideoPlayerState> {
  VideoPlayerBloc({
    required LocalPlaybackEngine localEngine,
    required CastPlaybackEngine castEngine,
    required CastDeviceManager castDeviceManager,
    required PlaybackTracker playbackTracker,
    required MediaUrlService urlGenerator,
    required MediaRemoteDataSource dataSource,
    required JellyfinClientService jellyfinClientService,
  }) : _localEngine = localEngine,
       _castEngine = castEngine,
       _castDeviceManager = castDeviceManager,
       _playbackTracker = playbackTracker,
       _urlGenerator = urlGenerator,
       _dataSource = dataSource,
       _jellyfinClientService = jellyfinClientService,
       super(const VideoPlayerState()) {
    on<PlayerPlayRequested>(_onPlayRequested);
    on<PlayerStopRequested>(_onStopRequested);
    on<PlayerPauseRequested>(_onPauseRequested);
    on<PlayerResumeRequested>(_onResumeRequested);
    on<PlayerSeekRequested>(_onSeekRequested);
    on<PlayerTogglePlayPauseRequested>(_onTogglePlayPause);
    on<PlayerCastRequested>(_onCastRequested);
    on<PlayerSkipIntroRequested>(_onSkipIntroRequested);
    on<PlayerTrackSelected>(_onTrackSelected);
    on<_EngineStateUpdated>(_onInternalEngineStateUpdated);

    _initCastListeners();
  }

  final LocalPlaybackEngine _localEngine;
  final CastPlaybackEngine _castEngine;
  final CastDeviceManager _castDeviceManager;
  final PlaybackTracker _playbackTracker;
  final MediaUrlService _urlGenerator;
  final MediaRemoteDataSource _dataSource;
  final JellyfinClientService _jellyfinClientService;

  PlaybackEngine? _activeEngine;
  StreamSubscription<PlaybackEngineState>? _engineSub;
  StreamSubscription<GoogleCastSession?>? _castSessionSub;
  DateTime _lastProgressReport = DateTime.now();
  bool _isLocalMedia = false;
  bool _wasCasting = false;

  PlaybackEngine get _engine {
    if (_activeEngine == null) throw StateError('No active engine');
    return _activeEngine!;
  }

  void _initCastListeners() {
    _castSessionSub = _castDeviceManager.currentSessionStream.listen((_) {
      final connected = _castDeviceManager.isConnected;
      if (!connected && _wasCasting) {
        add(PlayerStopRequested());
      }
      _wasCasting = connected;
    });
  }

  void _subscribeToEngine(PlaybackEngine engine) {
    _engineSub?.cancel();
    _engineSub = engine.stateStream.listen((engineState) {
      if (isClosed) return;
      add(_EngineStateUpdated(engineState));
    });
  }

  void _onInternalEngineStateUpdated(
    _EngineStateUpdated event,
    Emitter<VideoPlayerState> emit,
  ) {
    final engineState = event.engineState;
    final item = state.mediaItem;
    var showSkip = false;

    if (item != null) {
      final introStart = item.introStartTicks;
      final introEnd = item.introEndTicks;
      if (introStart != null && introEnd != null) {
        final currentTicks = engineState.position.inMicroseconds * 10;
        if (currentTicks >= introStart && currentTicks < introEnd) {
          showSkip = true;
        }
      }
    }

    final newStatus = _determineStatus(engineState);

    emit(
      state.copyWith(
        position: engineState.position,
        duration: engineState.duration,
        isBuffering: engineState.isBuffering,
        showSkipIntro: showSkip,
        status: newStatus,
        nativeViewAttachment: _activeEngine?.nativeViewAttachment,
      ),
    );

    if (newStatus == VideoPlayerStatus.playing) {
      _handleProgressReporting(engineState.position);
    }
  }

  VideoPlayerStatus _determineStatus(PlaybackEngineState engineState) {
    if (state.status == VideoPlayerStatus.loading) {
      if (!engineState.isBuffering && engineState.position > Duration.zero) {
        return VideoPlayerStatus.playing;
      }
      return VideoPlayerStatus.loading;
    }
    if (engineState.isCompleted) {
      return VideoPlayerStatus.stopped;
    }
    if (engineState.isPlaying) {
      return VideoPlayerStatus.playing;
    }
    if (state.status == VideoPlayerStatus.playing && !engineState.isPlaying) {
      return VideoPlayerStatus.paused;
    }
    return state.status;
  }

  Future<void> _handleProgressReporting(Duration position) async {
    if (_isLocalMedia ||
        state.mediaItem == null ||
        state.isCasting ||
        state.status != VideoPlayerStatus.playing) {
      return;
    }

    if (DateTime.now().difference(_lastProgressReport).inSeconds > 10) {
      _lastProgressReport = DateTime.now();
      final ticks = position.inMicroseconds * 10;
      await _playbackTracker.reportPlaybackProgress(
        itemId: state.mediaItem!.id,
        positionTicks: ticks,
      );
    }
  }

  Future<PlayableMedia> _buildPlayableMedia(
    MediaItem item, {
    String? localPath,
    bool forCast = false,
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

  Future<void> _onPlayRequested(
    PlayerPlayRequested event,
    Emitter<VideoPlayerState> emit,
  ) async {
    LoggerService.player.info('Play requested for ${event.item.name}');

    final useCast = _castDeviceManager.isConnected;

    if (useCast) {
      emit(
        state.copyWith(
          status: VideoPlayerStatus.loading,
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
        _activeEngine = _castEngine;
        _subscribeToEngine(_castEngine);
        await _castEngine.load(playableMedia);
      } on Exception catch (e) {
        LoggerService.player.severe('Failed to start cast playback', e);
        emit(state.copyWith(status: VideoPlayerStatus.error));
      }
      return;
    }

    emit(
      state.copyWith(
        status: VideoPlayerStatus.loading,
        mediaItem: event.item,
        localPath: event.localPath,
        isLocalMedia: event.localPath != null,
        isCasting: false,
      ),
    );
    _isLocalMedia = event.localPath != null;

    if (event.localPath == null) {
      unawaited(_playbackTracker.reportPlaybackStart(event.item.id));
    }

    try {
      final playableMedia = await _buildPlayableMedia(
        event.item,
        localPath: event.localPath,
        forCast: false,
      );
      _activeEngine = _localEngine;
      _subscribeToEngine(_localEngine);
      await _localEngine.load(playableMedia);
    } on Exception catch (e) {
      LoggerService.player.severe('Failed to play media', e);
      emit(state.copyWith(status: VideoPlayerStatus.error));
    }
  }

  Future<void> _onStopRequested(
    PlayerStopRequested event,
    Emitter<VideoPlayerState> emit,
  ) async {
    final finalPosition = state.position;
    final item = state.mediaItem;

    if (_activeEngine != null) {
      await _activeEngine!.stop();
      _activeEngine = null;
    }

    await _engineSub?.cancel();
    _engineSub = null;

    if (item != null && !_isLocalMedia) {
      await _playbackTracker.reportPlaybackStopped(
        itemId: item.id,
        positionTicks: finalPosition.inMicroseconds * 10,
      );
    }

    emit(
      state.copyWith(
        status: VideoPlayerStatus.stopped,
        position: finalPosition,
        showSkipIntro: false,
        isCasting: false,
        nativeViewAttachment: null,
      ),
    );
  }

  Future<void> _onPauseRequested(
    PlayerPauseRequested event,
    Emitter<VideoPlayerState> emit,
  ) async {
    await _engine.pause();
    emit(state.copyWith(status: VideoPlayerStatus.paused));
  }

  Future<void> _onResumeRequested(
    PlayerResumeRequested event,
    Emitter<VideoPlayerState> emit,
  ) async {
    await _engine.play();
    emit(state.copyWith(status: VideoPlayerStatus.playing));
  }

  Future<void> _onSeekRequested(
    PlayerSeekRequested event,
    Emitter<VideoPlayerState> emit,
  ) async {
    await _engine.seek(event.position);
  }

  Future<void> _onTogglePlayPause(
    PlayerTogglePlayPauseRequested event,
    Emitter<VideoPlayerState> emit,
  ) async {
    if (state.status == VideoPlayerStatus.playing) {
      add(PlayerPauseRequested());
    } else {
      add(PlayerResumeRequested());
    }
  }

  Future<void> _onCastRequested(
    PlayerCastRequested event,
    Emitter<VideoPlayerState> emit,
  ) async {
    LoggerService.player.info('Cast requested for ${event.item.name}');

    if (_activeEngine != null && !state.isCasting) {
      await _activeEngine!.stop();
    }

    emit(
      state.copyWith(
        status: VideoPlayerStatus.loading,
        mediaItem: event.item,
        isCasting: true,
        isLocalMedia: false,
      ),
    );
    _isLocalMedia = false;

    try {
      if (!_castDeviceManager.isConnected) {
        final connected = await _castDeviceManager.waitUntilConnected();
        if (!connected) {
          emit(state.copyWith(status: VideoPlayerStatus.error));
          return;
        }
      }

      final playableMedia = await _buildPlayableMedia(
        event.item,
        forCast: true,
      );
      _activeEngine = _castEngine;
      _subscribeToEngine(_castEngine);
      await _castEngine.load(playableMedia);
    } on Exception catch (e) {
      LoggerService.player.severe('Failed to cast media', e);
      emit(state.copyWith(status: VideoPlayerStatus.error));
    }
  }

  Future<void> _onSkipIntroRequested(
    PlayerSkipIntroRequested event,
    Emitter<VideoPlayerState> emit,
  ) async {
    final item = state.mediaItem;
    final introEndTicks = item?.introEndTicks;
    if (item != null && introEndTicks != null) {
      final endDuration = Duration(microseconds: introEndTicks ~/ 10);
      await _engine.seek(endDuration);
      emit(state.copyWith(showSkipIntro: false));
    }
  }

  Future<void> _onTrackSelected(
    PlayerTrackSelected event,
    Emitter<VideoPlayerState> emit,
  ) async {
    if (event.type == TrackType.audio) {
      await _localEngine.setAudioTrack(event.index);
    } else {
      await _localEngine.setSubtitleTrack(event.index);
    }
  }

  @override
  Future<void> close() {
    unawaited(_engineSub?.cancel());
    unawaited(_castSessionSub?.cancel());
    if (_activeEngine != null) {
      unawaited(_activeEngine!.stop());
    }
    return super.close();
  }
}
