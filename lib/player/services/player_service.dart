import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:playcado/player/models/playable_media.dart';

abstract class PlayerService {
  PlayerServiceState get currentState;

  PlayerView? get playerView;

  Stream<PlayerServiceState> get stateStream;

  Future<void> dispose();

  Future<void> load(PlayableMedia media);

  Future<void> pause();

  Future<void> play();

  Future<void> seek(Duration position);

  Future<void> setAudioTrack(int index);

  Future<void> setSubtitleTrack(int index);

  Future<void> stop();
}

class PlayerServiceState extends Equatable {
  const PlayerServiceState({
    this.duration = Duration.zero,
    this.isBuffering = false,
    this.isCompleted = false,
    this.isPlaying = false,
    this.position = Duration.zero,
  });

  final Duration duration;
  final bool isBuffering;
  final bool isCompleted;
  final bool isPlaying;
  final Duration position;

  PlayerServiceState copyWith({
    Duration? duration,
    bool? isBuffering,
    bool? isCompleted,
    bool? isPlaying,
    Duration? position,
  }) {
    return PlayerServiceState(
      duration: duration ?? this.duration,
      isBuffering: isBuffering ?? this.isBuffering,
      isCompleted: isCompleted ?? this.isCompleted,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
    );
  }

  @override
  List<Object?> get props => [
    duration,
    isBuffering,
    isCompleted,
    isPlaying,
    position,
  ];
}

sealed class PlayerView {
  const PlayerView();
}

class LocalPlayerView extends PlayerView {
  const LocalPlayerView(this.controller);

  final Object controller; // VideoController
}

class CastPlayerView extends PlayerView {
  const CastPlayerView();
}
