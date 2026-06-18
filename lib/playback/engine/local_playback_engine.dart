import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:playcado/playback/engine/playback_engine.dart';
import 'package:playcado/playback/models/playable_media.dart';
import 'package:playcado/playback/models/track_info.dart';
import 'package:playcado/services/logger_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Plays media on the local device using [media_kit]'s [Player].
///
/// Manages audio session, wake lock, and audio/subtitle track selection.
/// Shares a single [Player] instance for the app's lifetime to avoid
/// native resource churn.
class LocalPlaybackEngine implements PlaybackEngine {
  LocalPlaybackEngine() {
    _init();
  }

  late final Player _player;
  late final VideoController _controller;
  final StreamController<PlaybackEngineState> _stateController =
      StreamController<PlaybackEngineState>.broadcast();
  PlaybackEngineState _currentState = const PlaybackEngineState();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _bufferingSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<bool>? _completedSub;

  @override
  Stream<PlaybackEngineState> get stateStream => _stateController.stream;

  @override
  PlaybackEngineState get currentState => _currentState;

  @override
  Object? get nativeViewAttachment => _controller;

  /// Available audio tracks for the current media.
  List<TrackInfo> get audioTracks {
    final tracks = _player.state.tracks.audio;
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

  /// Available subtitle tracks for the current media.
  List<TrackInfo> get subtitleTracks {
    final tracks = _player.state.tracks.subtitle;
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

  /// Index of the currently selected audio track.
  int get currentAudioTrackIndex {
    final current = _player.state.track.audio;
    final tracks = _player.state.tracks.audio;
    return tracks.indexOf(current);
  }

  /// Index of the currently selected subtitle track.
  int get currentSubtitleTrackIndex {
    final current = _player.state.track.subtitle;
    final tracks = _player.state.tracks.subtitle;
    return tracks.indexOf(current);
  }

  /// Sets the active audio track by [index] into [audioTracks].
  Future<void> setAudioTrack(int index) async {
    final tracks = _player.state.tracks.audio;
    if (index >= 0 && index < tracks.length) {
      await _player.setAudioTrack(tracks[index]);
    }
  }

  /// Sets the active subtitle track by [index] into [subtitleTracks].
  Future<void> setSubtitleTrack(int index) async {
    final tracks = _player.state.tracks.subtitle;
    if (index >= 0 && index < tracks.length) {
      await _player.setSubtitleTrack(tracks[index]);
    }
  }

  /// Creates the [Player] and [VideoController], configures audio session,
  /// and wires up state streams.
  void _init() {
    _player = Player();
    _controller = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        androidAttachSurfaceAfterVideoParameters: true,
      ),
    );
    unawaited(_initAudioSession());
    _setupStreams();
  }

  /// Configures the audio session for movie playback with media usage.
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

  /// Subscribes to the native Player streams and forwards updates to state.
  void _setupStreams() {
    _positionSub = _player.stream.position.listen((position) {
      _updateState(position: position);
    });
    _playingSub = _player.stream.playing.listen((isPlaying) {
      _updateState(isPlaying: isPlaying);
    });
    _bufferingSub = _player.stream.buffering.listen((isBuffering) {
      _updateState(isBuffering: isBuffering);
    });
    _durationSub = _player.stream.duration.listen((duration) {
      _updateState(duration: duration);
    });
    _completedSub = _player.stream.completed.listen((isCompleted) {
      _updateState(isCompleted: isCompleted);
    });
  }

  /// Merges new values into [_currentState] and emits on [_stateController].
  void _updateState({
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isBuffering,
    bool? isCompleted,
  }) {
    _currentState = _currentState.copyWith(
      position: position,
      duration: duration,
      isPlaying: isPlaying,
      isBuffering: isBuffering,
      isCompleted: isCompleted,
    );
    _stateController.add(_currentState);
  }

  @override
  Future<void> load(PlayableMedia media) async {
    LoggerService.player.info('LocalPlaybackEngine loading: ${media.title}');
    await WakelockPlus.enable();

    await _player.open(
      Media(media.streamUrl, httpHeaders: media.httpHeaders),
      play: false,
    );

    if (media.startPosition > Duration.zero) {
      await _player.stream.duration.firstWhere((d) => d > Duration.zero);
      await _player.seek(media.startPosition);
    }
    await _player.play();
  }

  @override
  Future<void> play() async => _player.play();

  @override
  Future<void> pause() async => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await WakelockPlus.disable();
  }

  @override
  Future<void> seek(Duration position) async => _player.seek(position);

  @override
  Future<void> dispose() async {
    await _positionSub?.cancel();
    await _playingSub?.cancel();
    await _bufferingSub?.cancel();
    await _durationSub?.cancel();
    await _completedSub?.cancel();
    await _player.dispose();
    await _stateController.close();
    await WakelockPlus.disable();
  }
}
