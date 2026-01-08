import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/status_wrapper.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/media/repos/library_repository.dart';
import 'package:playcado/media/repos/playback_repository.dart';
import 'package:playcado/services/logger_service.dart';

part 'movie_details_event.dart';
part 'movie_details_state.dart';

class MovieDetailsBloc extends Bloc<MovieDetailsEvent, MovieDetailsState> {
  MovieDetailsBloc({
    required LibraryRepository libraryRepository,
    required PlaybackRepository playbackRepository,
  }) : _libraryRepository = libraryRepository,
       _playbackRepository = playbackRepository,
       super(const MovieDetailsState()) {
    on<FetchMovieDetails>(_onFetchMovieDetails);
    on<ToggleMoviePlayedStatus>(_onToggleMoviePlayedStatus);
    on<UpdateMoviePlaybackProgress>(_onUpdateMoviePlaybackProgress);
  }
  final LibraryRepository _libraryRepository;
  final PlaybackRepository _playbackRepository;

  Future<void> _onFetchMovieDetails(
    FetchMovieDetails event,
    Emitter<MovieDetailsState> emit,
  ) async {
    emit(state.copyWith(movie: const StatusLoading()));

    try {
      final item = await _libraryRepository.getItem(event.remoteId);
      emit(state.copyWith(movie: StatusSuccess(item)));
    } on Exception catch (error) {
      LoggerService.media.severe('Failed to fetch movie details', error);
      emit(state.copyWith(movie: StatusError(error.toString())));
    }
  }

  Future<void> _onToggleMoviePlayedStatus(
    ToggleMoviePlayedStatus event,
    Emitter<MovieDetailsState> emit,
  ) async {
    final currentItem = state.movie.value;
    if (currentItem == null) return;

    final newPlayedStatus = !currentItem.isPlayed;
    final updatedItem = currentItem.copyWith(isPlayed: newPlayedStatus);

    emit(state.copyWith(movie: StatusSuccess(updatedItem)));

    try {
      await _playbackRepository.togglePlayedStatus(
        currentItem.id,
        isPlayed: newPlayedStatus,
      );
    } on Exception catch (e, stackTrace) {
      LoggerService.media.severe(
        'Failed to toggle movie played status',
        e,
        stackTrace,
      );
    }
  }

  void _onUpdateMoviePlaybackProgress(
    UpdateMoviePlaybackProgress event,
    Emitter<MovieDetailsState> emit,
  ) {
    final movie = state.movie.value;
    if (movie != null) {
      final updated = movie.copyWith(
        playbackPositionTicks: event.positionTicks,
      );
      emit(state.copyWith(movie: StatusSuccess(updated)));
    }
  }
}
