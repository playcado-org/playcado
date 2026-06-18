import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:playcado/player/models/playable_media.dart';

class PlayerEngineState extends Equatable {
  const PlayerEngineState({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isCompleted = false,
  });

  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isBuffering;
  final bool isCompleted;

  PlayerEngineState copyWith({
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isBuffering,
    bool? isCompleted,
  }) {
    return PlayerEngineState(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
    position,
    duration,
    isPlaying,
    isBuffering,
    isCompleted,
  ];
}

abstract class PlayerEngine {
  Stream<PlayerEngineState> get stateStream;

  PlayerEngineState get currentState;

  Future<void> load(PlayableMedia media);

  Future<void> play();

  Future<void> pause();

  Future<void> stop();

  Future<void> seek(Duration position);

  Future<void> dispose();

  Object? get nativeViewAttachment;
}
