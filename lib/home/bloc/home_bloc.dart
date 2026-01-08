import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/status_wrapper.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/media/repos/library_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required LibraryRepository libraryRepository})
    : _libraryRepository = libraryRepository,
      super(const HomeState()) {
    on<LoadHomeContent>(_onLoadHomeContent);
  }
  final LibraryRepository _libraryRepository;

  Future<void> _onLoadHomeContent(
    LoadHomeContent event,
    Emitter<HomeState> emit,
  ) async {
    emit(
      state.copyWith(
        continueWatching: StatusLoading(
          previousValue: state.continueWatching.value,
        ),
        nextUp: StatusLoading(
          previousValue: state.nextUp.value,
        ),
        latestMovies: StatusLoading(
          previousValue: state.latestMovies.value,
        ),
        latestTv: StatusLoading(previousValue: state.latestTv.value),
      ),
    );

    List<MediaItem>? resumeItems;
    List<MediaItem>? nextUpItems;
    List<MediaItem>? latestMovies;
    List<MediaItem>? latestTv;
    String? resumeErr;
    String? nextUpErr;
    String? moviesErr;
    String? tvErr;

    try {
      resumeItems = await _libraryRepository.getResumeItems();
    } on Exception catch (e) {
      resumeErr = e.toString();
    }
    try {
      nextUpItems = await _libraryRepository.getNextUpItems();
    } on Exception catch (e) {
      nextUpErr = e.toString();
    }
    try {
      latestMovies = await _libraryRepository.getLatestMovies();
    } on Exception catch (e) {
      moviesErr = e.toString();
    }
    try {
      latestTv = await _libraryRepository.getLatestTvShows();
    } on Exception catch (e) {
      tvErr = e.toString();
    }

    emit(
      state.copyWith(
        continueWatching: resumeErr != null
            ? StatusError(resumeErr)
            : StatusSuccess(resumeItems!),
        nextUp: nextUpErr != null
            ? StatusError(nextUpErr)
            : StatusSuccess(nextUpItems!),
        latestMovies: moviesErr != null
            ? StatusError(moviesErr)
            : StatusSuccess(latestMovies!),
        latestTv: tvErr != null ? StatusError(tvErr) : StatusSuccess(latestTv!),
      ),
    );
  }
}
