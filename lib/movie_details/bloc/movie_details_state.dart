part of 'movie_details_bloc.dart';

class MovieDetailsState extends Equatable {
  const MovieDetailsState({this.movie = const StatusInitial()});
  final StatusWrapper<MediaItem> movie;

  MovieDetailsState copyWith({StatusWrapper<MediaItem>? movie}) {
    return MovieDetailsState(movie: movie ?? this.movie);
  }

  @override
  List<Object?> get props => [movie];
}
