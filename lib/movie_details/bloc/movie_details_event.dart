part of 'movie_details_bloc.dart';

sealed class MovieDetailsEvent extends Equatable {
  const MovieDetailsEvent();

  @override
  List<Object?> get props => [];
}

final class FetchMovieDetails extends MovieDetailsEvent {
  const FetchMovieDetails(this.remoteId);
  final String remoteId;

  @override
  List<Object> get props => [remoteId];
}

final class ToggleMoviePlayedStatus extends MovieDetailsEvent {
  const ToggleMoviePlayedStatus();
}

final class UpdateMoviePlaybackProgress extends MovieDetailsEvent {
  const UpdateMoviePlaybackProgress(this.positionTicks);
  final int positionTicks;

  @override
  List<Object> get props => [positionTicks];
}
