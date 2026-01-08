import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:playcado/cast/cast.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/media/repos/playback_repository.dart';
import 'package:playcado/services/jellyfin_client_service.dart';
import 'package:playcado/services/logger_service.dart';
import 'package:playcado/services/media_url/media_url_service.dart';
import 'package:playcado/video_player/services/player_service.dart';

part 'video_player_event.dart';
part 'video_player_state.dart';

class VideoPlayerBloc extends Bloc<VideoPlayerEvent, VideoPlayerState> {
  VideoPlayerBloc({
    required PlaybackRepository playbackRepository,
    required MediaUrlService urlGenerator,
    required PlayerService playerService,
    required CastService castService,
    required JellyfinClientService jellyfinClientService,
  }) : _playbackRepository = playbackRepository,
       _urlGenerator = urlGenerator,
       _playerService = playerService,
       _castService = castService,
       _jellyfinClientService = jellyfinClientService,
       super(const VideoPlayerState()) {
    on<PlayerPlayRequested>(_onPlayRequested);
    on<PlayerStopRequested>(_onStopRequested);
    on<PlayerPauseRequested>(_onPauseRequested);
    on<PlayerResumeRequested>(_onResumeRequested);
    on<PlayerPositionUpdated>(_onPositionUpdated);
    on<PlayerStatusUpdated>(_onStatusUpdated);
    on<PlayerCastRequested>(_onCastRequested);
    on<PlayerSkipIntroRequested>(_onSkipIntroRequested);

    _initListeners();
  }
  final PlaybackRepository _playbackRepository;
  final MediaUrlService _urlGenerator;
  final PlayerService _playerService;
  final CastService _castService;
  final JellyfinClientService _jellyfinClientService;

  StreamSubscription<Duration>? _playerSub;
  StreamSubscription<bool>? _playerStatusSub;
  StreamSubscription<GoogleCastSession?>? _castSessionSub;
  StreamSubscription<GoggleCastMediaStatus?>? _castMediaStatusSub;
  DateTime _lastProgressReport = DateTime.now();

  void _initListeners() {
    _playerSub = _playerService.player.stream.position.listen((position) {
      if (state.status == VideoPlayerStatus.playing) {
        add(PlayerPositionUpdated(position));
      }
    });

    _playerStatusSub = _playerService.player.stream.playing.listen((isPlaying) {
      add(PlayerStatusUpdated(isPlaying: isPlaying));
    });

    _castSessionSub = _castService.currentSessionStream.listen((session) {
      final connState = session?.connectionState;
      final isActive =
          connState == GoogleCastConnectState.connected ||
          connState == GoogleCastConnectState.connecting;

      if (!isActive && state.isCasting) {
        add(PlayerStopRequested());
      }
    });

    _castMediaStatusSub = _castService.mediaStatusStream.listen((status) {
      if (state.isCasting && status != null) {
        final isPlaying =
            status.playerState == CastMediaPlayerState.playing ||
            status.playerState == CastMediaPlayerState.buffering;
        add(PlayerStatusUpdated(isPlaying: isPlaying));
      }
    });
  }

  Future<void> _onPlayRequested(
    PlayerPlayRequested event,
    Emitter<VideoPlayerState> emit,
  ) async {
    LoggerService.player.info('Play requested for ${event.item.name}');

    final startTicks = event.item.playbackPositionTicks ?? 0;
    final startPosition = startTicks > 0
        ? Duration(microseconds: startTicks ~/ 10)
        : null;

    if (_castService.isConnected) {
      emit(
        state.copyWith(
          status: VideoPlayerStatus.loading,
          mediaItem: event.item,
          isCasting: true,
          isLocalMedia: false,
        ),
      );

      try {
        final streamUrl = await _playbackRepository.getCastUrl(
          event.item.id,
        );
        final imageUrl = _urlGenerator.getImageUrl(event.item.id);

        await _castService.loadMedia(
          CastItem(
            mediaItem: event.item,
            streamUrl: streamUrl,
            imageUrl: imageUrl,
          ),
          playPosition: startPosition,
        );

        emit(state.copyWith(status: VideoPlayerStatus.playing));
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

    if (event.localPath == null) {
      unawaited(_playbackRepository.reportPlaybackStart(event.item.id));
    }

    try {
      String source;
      Map<String, String>? headers;

      if (event.localPath != null) {
        source = event.localPath!;
      } else {
        source = _playbackRepository.getStreamUrl(event.item.id);
        headers = {
          'X-Emby-Authorization':
              'MediaBrowser Client="Playcado", '
              'Device="Flutter", '
              'DeviceId="${_jellyfinClientService.deviceId}", '
              'Version="1.0.0", '
              'Token="${_jellyfinClientService.accessToken}"',
        };
      }

      await _playerService.playMedia(
        source,
        headers: headers,
        startPosition: startPosition,
      );
      emit(state.copyWith(status: VideoPlayerStatus.playing));
    } on Exception catch (e) {
      LoggerService.player.severe('Failed to play media', e);
      emit(state.copyWith(status: VideoPlayerStatus.error));
    }
  }

  Future<void> _onStopRequested(
    PlayerStopRequested event,
    Emitter<VideoPlayerState> emit,
  ) async {
    // 1. Capture the final position before stopping the service
    final finalPosition = state.isCasting
        ? state.position
        : _playerService.player.state.position;

    final item = state.mediaItem;

    if (state.isCasting) {
      await _castService.stop();
    } else {
      await _playerService.stop();

      if (item != null && !state.isLocalMedia) {
        await _playbackRepository.reportPlaybackStopped(
          itemId: item.id,
          positionTicks: finalPosition.inMicroseconds * 10,
        );
      }
    }

    // 2. Emit stopped status but KEEP the item and the final position
    // This allows the UI listener to see what stopped and where it ended.
    emit(
      state.copyWith(
        status: VideoPlayerStatus.stopped,
        position: finalPosition,
        showSkipIntro: false,
        isCasting: false,
      ),
    );
  }

  Future<void> _onPauseRequested(
    PlayerPauseRequested event,
    Emitter<VideoPlayerState> emit,
  ) async {
    if (state.isCasting) {
      await _castService.pause();
    } else {
      await _playerService.pause();
    }
    emit(state.copyWith(status: VideoPlayerStatus.paused));
  }

  Future<void> _onResumeRequested(
    PlayerResumeRequested event,
    Emitter<VideoPlayerState> emit,
  ) async {
    if (state.isCasting) {
      await _castService.play();
    } else {
      await _playerService.play();
    }
    emit(state.copyWith(status: VideoPlayerStatus.playing));
  }

  Future<void> _onPositionUpdated(
    PlayerPositionUpdated event,
    Emitter<VideoPlayerState> emit,
  ) async {
    final item = state.mediaItem;
    var showSkip = false;

    final introStart = item?.introStartTicks;
    final introEnd = item?.introEndTicks;
    if (introStart != null && introEnd != null) {
      final currentTicks = event.position.inMicroseconds * 10;
      if (currentTicks >= introStart && currentTicks < introEnd) {
        showSkip = true;
      }
    }

    if (state.showSkipIntro != showSkip || state.position != event.position) {
      emit(state.copyWith(showSkipIntro: showSkip, position: event.position));
    }

    if (state.isLocalMedia ||
        item == null ||
        state.isCasting ||
        state.status != VideoPlayerStatus.playing) {
      return;
    }

    if (DateTime.now().difference(_lastProgressReport).inSeconds > 10) {
      _lastProgressReport = DateTime.now();
      final ticks = event.position.inMicroseconds * 10;
      await _playbackRepository.reportPlaybackProgress(
        itemId: item.id,
        positionTicks: ticks,
      );
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
      if (state.isCasting) {
        await _castService.seek(endDuration);
      } else {
        await _playerService.player.seek(endDuration);
      }
      emit(state.copyWith(showSkipIntro: false));
    }
  }

  void _onStatusUpdated(
    PlayerStatusUpdated event,
    Emitter<VideoPlayerState> emit,
  ) {
    if (state.status != VideoPlayerStatus.stopped && !state.isCasting) {
      emit(
        state.copyWith(
          status: event.isPlaying
              ? VideoPlayerStatus.playing
              : VideoPlayerStatus.paused,
        ),
      );
    }
  }

  Future<void> _onCastRequested(
    PlayerCastRequested event,
    Emitter<VideoPlayerState> emit,
  ) async {
    LoggerService.player.info('Cast requested for ${event.item.name}');

    if (state.isActive && !state.isCasting) {
      await _playerService.stop();
    }

    emit(
      state.copyWith(
        status: VideoPlayerStatus.loading,
        mediaItem: event.item,
        isCasting: true,
        isLocalMedia: false,
      ),
    );

    try {
      if (!_castService.isConnected) {
        final connected = await _castService.waitUntilConnected();
        if (!connected) {
          emit(state.copyWith(status: VideoPlayerStatus.error));
          return;
        }
      }

      final startTicks = event.item.playbackPositionTicks ?? 0;
      final startPosition = startTicks > 0
          ? Duration(microseconds: startTicks ~/ 10)
          : null;

      final streamUrl = await _playbackRepository.getCastUrl(event.item.id);
      final imageUrl = _urlGenerator.getImageUrl(event.item.id);

      await _castService.loadMedia(
        CastItem(
          mediaItem: event.item,
          streamUrl: streamUrl,
          imageUrl: imageUrl,
        ),
        playPosition: startPosition,
      );
      emit(state.copyWith(status: VideoPlayerStatus.playing));
    } on Exception catch (e) {
      LoggerService.player.severe('Failed to cast media', e);
      emit(state.copyWith(status: VideoPlayerStatus.error));
    }
  }

  @override
  Future<void> close() {
    unawaited(_playerSub?.cancel());
    unawaited(_playerStatusSub?.cancel());
    unawaited(_castSessionSub?.cancel());
    unawaited(_castMediaStatusSub?.cancel());
    unawaited(_playerService.stop());
    return super.close();
  }
}
