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
        nextUp: StatusLoading(previousValue: state.nextUp.value),
        latestMovies: StatusLoading(previousValue: state.latestMovies.value),
        latestTv: StatusLoading(previousValue: state.latestTv.value),
      ),
    );

    Future<({dynamic value, String? error})> fetch(
      Future<List<MediaItem>> Function() call,
    ) async {
      try {
        return (value: await call(), error: null);
      } on Exception catch (e) {
        return (value: null, error: e.toString());
      }
    }

    final results = await Future.wait([
      fetch(_libraryRepository.getResumeItems),
      fetch(_libraryRepository.getNextUpItems),
      fetch(_libraryRepository.getLatestMovies),
      fetch(_libraryRepository.getLatestTvShows),
    ]);

    emit(
      state.copyWith(
        continueWatching: results[0].error != null
            ? StatusError(results[0].error!)
            : StatusSuccess<List<MediaItem>>(results[0].value as List<MediaItem>),
        nextUp: results[1].error != null
            ? StatusError(results[1].error!)
            : StatusSuccess<List<MediaItem>>(results[1].value as List<MediaItem>),
        latestMovies: results[2].error != null
            ? StatusError(results[2].error!)
            : StatusSuccess<List<MediaItem>>(results[2].value as List<MediaItem>),
        latestTv: results[3].error != null
            ? StatusError(results[3].error!)
            : StatusSuccess<List<MediaItem>>(results[3].value as List<MediaItem>),
      ),
    );
  }
}
