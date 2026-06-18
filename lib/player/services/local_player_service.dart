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
  LocalPlayerService() {
    _init();
  }

  StreamSubscription<bool>? _bufferingSub;
  StreamSubscription<bool>? _completedSub;
  late final VideoController _controller;
  PlayerServiceState _currentState = const PlayerServiceState();
  StreamSubscription<Duration>? _durationSub;
  late final Player _player;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  final StreamController<PlayerServiceState> _stateController =
      StreamController<PlayerServiceState>.broadcast();

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

  int get currentAudioTrackIndex {
    final current = _player.state.track.audio;
    final tracks = _player.state.tracks.audio;
    return tracks.indexOf(current);
  }

  @override
  PlayerServiceState get currentState => _currentState;

  int get currentSubtitleTrackIndex {
    final current = _player.state.track.subtitle;
    final tracks = _player.state.tracks.subtitle;
    return tracks.indexOf(current);
  }

  @override
  PlayerView? get playerView => LocalPlayerView(_controller);

  @override
  Stream<PlayerServiceState> get stateStream => _stateController.stream;

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

  @override
  Future<void> load(PlayableMedia media) async {
    LoggerService.player.info('LocalPlayerService loading: ${media.title}');
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
  Future<void> pause() async => _player.pause();

  @override
  Future<void> play() async => _player.play();

  @override
  Future<void> seek(Duration position) async => _player.seek(position);

  Future<void> setAudioTrack(int index) async {
    final tracks = _player.state.tracks.audio;
    if (index >= 0 && index < tracks.length) {
      await _player.setAudioTrack(tracks[index]);
    }
  }

  Future<void> setSubtitleTrack(int index) async {
    final tracks = _player.state.tracks.subtitle;
    if (index >= 0 && index < tracks.length) {
      await _player.setSubtitleTrack(tracks[index]);
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await WakelockPlus.disable();
  }

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
}
