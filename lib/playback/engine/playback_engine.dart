import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:playcado/playback/models/playable_media.dart';

/// Snapshot of the current playback state, emitted via [PlaybackEngine.stateStream].
class PlaybackEngineState extends Equatable {
  const PlaybackEngineState({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isCompleted = false,
  });

  /// Current playback position.
  final Duration position;

  /// Total duration of the loaded media.
  final Duration duration;

  /// Whether media is currently playing.
  final bool isPlaying;

  /// Whether the engine is buffering data.
  final bool isBuffering;

  /// Whether playback has reached the end of the media.
  final bool isCompleted;

  /// Returns a copy with the given fields replaced.
  PlaybackEngineState copyWith({
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isBuffering,
    bool? isCompleted,
  }) {
    return PlaybackEngineState(
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

/// Abstract interface for a media playback engine.
///
/// Implementations can target local device playback ([LocalPlaybackEngine])
/// or remote Cast device playback ([CastPlaybackEngine]).
abstract class PlaybackEngine {
  /// Stream of continuous [PlaybackEngineState] updates.
  Stream<PlaybackEngineState> get stateStream;

  /// The latest snapshot of the engine's state.
  PlaybackEngineState get currentState;

  /// Loads [media] into the engine and begins playback.
  Future<void> load(PlayableMedia media);

  /// Resumes playback from the current position.
  Future<void> play();

  /// Pauses playback at the current position.
  Future<void> pause();

  /// Stops playback and resets the engine.
  Future<void> stop();

  /// Seeks to [position] in the current media.
  Future<void> seek(Duration position);

  /// Releases all resources held by the engine.
  Future<void> dispose();

  /// Platform-specific view attachment for rendering video output.
  ///
  /// Returns a [VideoController] for local playback or `null` for Cast.
  Object? get nativeViewAttachment;
}
