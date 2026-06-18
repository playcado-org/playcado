import 'dart:async';
import 'dart:io';

import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:playcado/player/models/playable_media.dart';
import 'package:playcado/player/services/player_service.dart';
import 'package:playcado/services/logger_service.dart';

class CastPlayerService implements PlayerService {
  CastPlayerService();

  PlayerServiceState _currentState = const PlayerServiceState();
  StreamSubscription<GoggleCastMediaStatus?>? _mediaStatusSub;
  final GoogleCastRemoteMediaClientPlatformInterface _remoteMediaClient =
      GoogleCastRemoteMediaClient.instance;
  final GoogleCastSessionManagerPlatformInterface _sessionManager =
      GoogleCastSessionManager.instance;
  final StreamController<PlayerServiceState> _stateController =
      StreamController<PlayerServiceState>.broadcast();

  @override
  Future<void> dispose() async {
    await _mediaStatusSub?.cancel();
    await _stateController.close();
  }

  @override
  Future<void> load(PlayableMedia media) async {
    LoggerService.player.info('CastPlayerService loading: ${media.title}');
    _updateState(isBuffering: true);

    _mediaStatusSub?.cancel();
    _mediaStatusSub = _remoteMediaClient.mediaStatusStream.listen((status) {
      if (status != null) {
        final isPlaying =
            status.playerState == CastMediaPlayerState.playing ||
            status.playerState == CastMediaPlayerState.buffering;
        _updateState(
          isPlaying: isPlaying,
          isBuffering: status.playerState == CastMediaPlayerState.buffering,
          duration: status.mediaInformation?.duration ?? Duration.zero,
        );
      }
    });

    final uri = Uri.parse(media.streamUrl);
    final mediaInfo = GoogleCastMediaInformation(
      contentId: media.streamUrl,
      contentUrl: uri,
      streamType: CastMediaStreamType.buffered,
      contentType: 'application/x-mpegURL',
      metadata: GoogleCastMovieMediaMetadata(
        title: media.title,
        subtitle: media.subtitle ?? '',
        studio: 'Playcado',
        releaseDate: DateTime.now(),
        images: [
          if (media.posterUrl.isNotEmpty)
            GoogleCastImage(
              url: Uri.parse(media.posterUrl),
              width: 480,
              height: 720,
            ),
        ],
      ),
    );

    try {
      if (Platform.isAndroid) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      await _remoteMediaClient.loadMedia(
        mediaInfo,
        playPosition: media.startPosition,
      );
      LoggerService.player.info('Cast loadMedia sent successfully');
      _updateState(isPlaying: true, isBuffering: false);
    } on Exception catch (e, stack) {
      LoggerService.player.severe('Failed to load media on Cast', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    if (!_isSupportedPlatform) return;
    _updateState(isPlaying: false);
    try {
      await _remoteMediaClient.pause();
    } on Exception catch (e, stack) {
      LoggerService.player.warning('Failed to pause cast', e, stack);
    }
  }

  @override
  Future<void> play() async {
    if (!_isSupportedPlatform) return;
    _updateState(isPlaying: true);
    try {
      await _remoteMediaClient.play();
    } on Exception catch (e, stack) {
      LoggerService.player.warning('Failed to play cast', e, stack);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (!_isSupportedPlatform) return;
    try {
      await _remoteMediaClient.seek(
        GoogleCastMediaSeekOption(position: position),
      );
    } on Exception catch (e, stack) {
      LoggerService.player.warning('Failed to seek cast', e, stack);
    }
  }

  @override
  Future<void> stop() async {
    if (!_isSupportedPlatform) return;
    _updateState(isPlaying: false);
    try {
      await _remoteMediaClient.stop();
    } on Exception catch (e, stack) {
      LoggerService.player.warning('Failed to stop cast', e, stack);
    }
  }

  void _updateState({
    Duration? duration,
    bool? isBuffering,
    bool? isCompleted,
    bool? isPlaying,
    Duration? position,
  }) {
    _currentState = _currentState.copyWith(
      duration: duration,
      isBuffering: isBuffering,
      isCompleted: isCompleted,
      isPlaying: isPlaying,
      position: position,
    );
    _stateController.add(_currentState);
  }

  @override
  PlayerServiceState get currentState => _currentState;

  @override
  Object? get nativeViewAttachment => null;

  @override
  Stream<PlayerServiceState> get stateStream => _stateController.stream;

  bool get _isSupportedPlatform => Platform.isIOS || Platform.isAndroid;

  bool get isConnected =>
      _sessionManager.connectionState == GoogleCastConnectState.connected;
}
