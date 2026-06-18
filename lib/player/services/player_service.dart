import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:playcado/player/models/playable_media.dart';

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

abstract class PlayerService {
  PlayerServiceState get currentState;

  Object? get nativeViewAttachment;

  Stream<PlayerServiceState> get stateStream;

  Future<void> dispose();

  Future<void> load(PlayableMedia media);

  Future<void> pause();

  Future<void> play();

  Future<void> seek(Duration position);

  Future<void> stop();
}
