import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/status_wrapper.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/media/repos/library_repository.dart';
import 'package:playcado/services/logger_service.dart';

part 'libraries_event.dart';
part 'libraries_state.dart';

class LibrariesBloc extends Bloc<LibrariesEvent, LibrariesState> {
  LibrariesBloc({required LibraryRepository libraryRepository})
    : _libraryRepository = libraryRepository,
      super(const LibrariesState()) {
    on<LibrariesLibariesFetched>(_onLoadLibraries);
  }
  final LibraryRepository _libraryRepository;

  Future<void> _onLoadLibraries(
    LibrariesLibariesFetched event,
    Emitter<LibrariesState> emit,
  ) async {
    emit(
      state.copyWith(
        libraries: StatusLoading(previousValue: state.libraries.value),
      ),
    );

    try {
      final libraries = await _libraryRepository.getLibraries();

      final supportedLibraries = libraries.where((lib) {
        final type = lib.collectionType?.toLowerCase();
        return type == 'movies' ||
            type == 'tvshows' ||
            type == 'homevideos' ||
            type == 'photos' ||
            type == 'music';
      }).toList();

      emit(state.copyWith(libraries: StatusSuccess(supportedLibraries)));
    } on Exception catch (error) {
      LoggerService.api.severe('Failed to load libraries', error);
      emit(state.copyWith(libraries: StatusError(error.toString())));
    }
  }
}
