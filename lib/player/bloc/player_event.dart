part of 'player_bloc.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class PlayerPlayRequested extends PlayerEvent {
  const PlayerPlayRequested({required this.item, this.localPath});

  final MediaItem item;
  final String? localPath;

  @override
  List<Object?> get props => [item, localPath];
}

class PlayerStopRequested extends PlayerEvent {}

class PlayerPauseRequested extends PlayerEvent {}

class PlayerResumeRequested extends PlayerEvent {}

class PlayerSeekRequested extends PlayerEvent {
  const PlayerSeekRequested(this.position);

  final Duration position;

  @override
  List<Object?> get props => [position];
}

class PlayerTogglePlayPauseRequested extends PlayerEvent {}

class PlayerCastRequested extends PlayerEvent {
  const PlayerCastRequested({required this.item});

  final MediaItem item;

  @override
  List<Object?> get props => [item];
}

class PlayerSkipIntroRequested extends PlayerEvent {}

enum TrackType { audio, subtitle }

class PlayerTrackSelected extends PlayerEvent {
  const PlayerTrackSelected({required this.type, required this.index});

  final TrackType type;
  final int index;

  @override
  List<Object?> get props => [type, index];
}
