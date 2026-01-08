part of 'home_bloc.dart';

class HomeState extends Equatable {
  const HomeState({
    this.continueWatching = const StatusInitial(),
    this.nextUp = const StatusInitial(),
    this.latestMovies = const StatusInitial(),
    this.latestTv = const StatusInitial(),
  });
  final StatusWrapper<List<MediaItem>> continueWatching;
  final StatusWrapper<List<MediaItem>> nextUp;
  final StatusWrapper<List<MediaItem>> latestMovies;
  final StatusWrapper<List<MediaItem>> latestTv;

  HomeState copyWith({
    StatusWrapper<List<MediaItem>>? continueWatching,
    StatusWrapper<List<MediaItem>>? nextUp,
    StatusWrapper<List<MediaItem>>? latestMovies,
    StatusWrapper<List<MediaItem>>? latestTv,
  }) {
    return HomeState(
      continueWatching: continueWatching ?? this.continueWatching,
      nextUp: nextUp ?? this.nextUp,
      latestMovies: latestMovies ?? this.latestMovies,
      latestTv: latestTv ?? this.latestTv,
    );
  }

  @override
  List<Object> get props => [continueWatching, nextUp, latestMovies, latestTv];
}
