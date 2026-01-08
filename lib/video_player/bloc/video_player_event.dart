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

class PlayerPositionUpdated extends VideoPlayerEvent {
  const PlayerPositionUpdated(this.position);
  final Duration position;

  @override
  List<Object?> get props => [position];
}

class PlayerStatusUpdated extends VideoPlayerEvent {
  const PlayerStatusUpdated({required this.isPlaying});
  final bool isPlaying;

  @override
  List<Object?> get props => [isPlaying];
}

class PlayerCastRequested extends VideoPlayerEvent {
  const PlayerCastRequested({required this.item});
  final MediaItem item;

  @override
  List<Object?> get props => [item];
}

class PlayerSkipIntroRequested extends VideoPlayerEvent {}
