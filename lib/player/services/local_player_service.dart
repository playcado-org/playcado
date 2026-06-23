import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:playcado/player/models/playable_media.dart';
import 'package:playcado/player/models/track_info.dart';
import 'package:playcado/player/services/player_service.dart';
import 'package:playcado/services/logger_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class LocalPlayerService implements PlayerService {
  LocalPlayerService();

  StreamSubscription<bool>? _bufferingSub;
  StreamSubscription<bool>? _completedSub;
  VideoController? _controller;
  PlayerServiceState _currentState = const PlayerServiceState();
  StreamSubscription<Duration>? _durationSub;
  DateTime? _lastPositionEmit;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  final StreamController<PlayerServiceState> _stateController =
      StreamController<PlayerServiceState>.broadcast();

  Player? _player;
  Player get _lazyPlayer {
    if (_player == null) {
      final player = Player();
      _player = player;
      _controller = VideoController(
        player,
        configuration: const VideoControllerConfiguration(
          androidAttachSurfaceAfterVideoParameters: true,
        ),
      );
      unawaited(_initAudioSession());
      _setupStreams(player);
    }
    return _player!;
  }

  List<TrackInfo> get audioTracks {
    final tracks = _lazyPlayer.state.tracks.audio;
    return List.generate(
      tracks.length,
      (i) => TrackInfo(
        index: i,
        id: tracks[i].id,
        language: tracks[i].language,
        title: tracks[i].title,
      ),
    );
  }

  int get currentAudioTrackIndex {
    final current = _lazyPlayer.state.track.audio;
    final tracks = _lazyPlayer.state.tracks.audio;
    return tracks.indexOf(current);
  }

  @override
  PlayerServiceState get currentState => _currentState;

  int get currentSubtitleTrackIndex {
    final current = _lazyPlayer.state.track.subtitle;
    final tracks = _lazyPlayer.state.tracks.subtitle;
    return tracks.indexOf(current);
  }

  @override
  PlayerView get playerView {
    // Ensure the player and video controller are initialized before
    // providing the view.  The controller is set up inside _lazyPlayer
    // and is guaranteed non-null after that point.
    final _ = _lazyPlayer;
    return LocalPlayerView(_controller!);
  }

  @override
  Stream<PlayerServiceState> get stateStream => _stateController.stream;

  List<TrackInfo> get subtitleTracks {
    final tracks = _lazyPlayer.state.tracks.subtitle;
    return List.generate(
      tracks.length,
      (i) => TrackInfo(
        index: i,
        id: tracks[i].id,
        language: tracks[i].language,
        title: tracks[i].title,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await _positionSub?.cancel();
    await _playingSub?.cancel();
    await _bufferingSub?.cancel();
    await _durationSub?.cancel();
    await _completedSub?.cancel();
    await _player?.dispose();
    await _stateController.close();
    await WakelockPlus.disable();
  }

  @override
  Future<void> load(PlayableMedia media) async {
    LoggerService.player.info('LocalPlayerService loading: ${media.title}');

    _currentState = const PlayerServiceState();

    await _lazyPlayer.open(
      Media(media.streamUrl, httpHeaders: media.httpHeaders),
    );

    if (media.startPosition > Duration.zero) {
      // Wait for the duration to become known before seeking.
      // Without this the seek may land before the media has loaded
      // enough to know its boundaries.
      await _lazyPlayer.stream.duration
          .firstWhere((d) => d > Duration.zero)
          .timeout(const Duration(seconds: 10), onTimeout: () => Duration.zero);
      await _lazyPlayer.seek(media.startPosition);
      await _lazyPlayer.stream.position
          .firstWhere((pos) => pos < const Duration(seconds: 3))
          .timeout(const Duration(seconds: 5))
          .then((_) => _lazyPlayer.seek(media.startPosition))
          .catchError((_) {});
    }
  }

  @override
  Future<void> pause() async => _lazyPlayer.pause();

  @override
  Future<void> play() async => _lazyPlayer.play();

  @override
  Future<void> seek(Duration position) async => _lazyPlayer.seek(position);

  @override
  Future<void> setAudioTrack(int index) async {
    final tracks = _lazyPlayer.state.tracks.audio;
    if (index >= 0 && index < tracks.length) {
      await _lazyPlayer.setAudioTrack(tracks[index]);
    }
  }

  @override
  Future<void> setSubtitleTrack(int index) async {
    final tracks = _lazyPlayer.state.tracks.subtitle;
    if (index >= 0 && index < tracks.length) {
      await _lazyPlayer.setSubtitleTrack(tracks[index]);
    }
  }

  @override
  Future<void> stop() async {
    await _lazyPlayer.stop();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
        avAudioSessionMode: AVAudioSessionMode.moviePlayback,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.movie,
          usage: AndroidAudioUsage.media,
        ),
        androidWillPauseWhenDucked: true,
      ),
    );
  }

  void _setupStreams(Player player) {
    _positionSub = player.stream.position.listen((position) {
      final now = DateTime.now();
      final duration = player.state.duration;

      // Always emit if the video is at the very end
      final isAtEnd = position >= duration && duration > Duration.zero;

      if (!isAtEnd &&
          _lastPositionEmit != null &&
          now.difference(_lastPositionEmit!) <
              const Duration(milliseconds: 200)) {
        return;
      }
      _lastPositionEmit = now;
      _updateState(position: position);
    });
    _playingSub = player.stream.playing.listen((isPlaying) {
      _updateState(isPlaying: isPlaying);
      if (isPlaying) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    });
    _bufferingSub = player.stream.buffering.listen((isBuffering) {
      _updateState(isBuffering: isBuffering);
    });
    _durationSub = player.stream.duration.listen((duration) {
      _updateState(duration: duration);
    });
    _completedSub = player.stream.completed.listen((isCompleted) {
      _updateState(isCompleted: isCompleted);
    });
  }

  void _updateState({
    Duration? duration,
    bool? isBuffering,
    bool? isCompleted,
    bool? isPlaying,
    Duration? position,
  }) {
    if (_stateController.isClosed) return;

    _currentState = _currentState.copyWith(
      duration: duration,
      isBuffering: isBuffering,
      isCompleted: isCompleted,
      isPlaying: isPlaying,
      position: position,
    );
    _stateController.add(_currentState);
  }
}
