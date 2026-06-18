part of 'player_bloc.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class PlayerCastRequested extends PlayerEvent {
  const PlayerCastRequested({required this.item});

  final MediaItem item;

  @override
  List<Object?> get props => [item];
}

class PlayerPauseRequested extends PlayerEvent {}

class PlayerPlayRequested extends PlayerEvent {
  const PlayerPlayRequested({required this.item, this.localPath});

  final MediaItem item;
  final String? localPath;

  @override
  List<Object?> get props => [item, localPath];
}

class PlayerResumeRequested extends PlayerEvent {}

class PlayerSeekRequested extends PlayerEvent {
  const PlayerSeekRequested(this.position);

  final Duration position;

  @override
  List<Object?> get props => [position];
}

class PlayerSkipIntroRequested extends PlayerEvent {}

class PlayerStopRequested extends PlayerEvent {}

class PlayerTogglePlayPauseRequested extends PlayerEvent {}

class PlayerTrackSelected extends PlayerEvent {
  const PlayerTrackSelected({required this.type, required this.index});

  final TrackType type;
  final int index;

  @override
  List<Object?> get props => [type, index];
}

class ServiceStateUpdated extends PlayerEvent {
  const ServiceStateUpdated(this.serviceState);
  final PlayerServiceState serviceState;

  @override
  List<Object?> get props => [serviceState];
}

enum TrackType { audio, subtitle }
