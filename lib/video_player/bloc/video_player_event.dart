part of 'video_player_bloc.dart';

abstract class VideoPlayerEvent extends Equatable {
  const VideoPlayerEvent();

  @override
  List<Object?> get props => [];
}

class PlayerPlayRequested extends VideoPlayerEvent {
  const PlayerPlayRequested({required this.item, this.localPath});

  final MediaItem item;
  final String? localPath;

  @override
  List<Object?> get props => [item, localPath];
}

class PlayerStopRequested extends VideoPlayerEvent {}

class PlayerPauseRequested extends VideoPlayerEvent {}

class PlayerResumeRequested extends VideoPlayerEvent {}

class PlayerSeekRequested extends VideoPlayerEvent {
  const PlayerSeekRequested(this.position);

  final Duration position;

  @override
  List<Object?> get props => [position];
}

class PlayerTogglePlayPauseRequested extends VideoPlayerEvent {}

class PlayerCastRequested extends VideoPlayerEvent {
  const PlayerCastRequested({required this.item});

  final MediaItem item;

  @override
  List<Object?> get props => [item];
}

class PlayerSkipIntroRequested extends VideoPlayerEvent {}

enum TrackType { audio, subtitle }

class PlayerTrackSelected extends VideoPlayerEvent {
  const PlayerTrackSelected({required this.type, required this.index});

  final TrackType type;
  final int index;

  @override
  List<Object?> get props => [type, index];
}
