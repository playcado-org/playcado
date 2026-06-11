import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/status_wrapper.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/search/repos/search_repository.dart';
import 'package:playcado/services/logger_service.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required SearchRepository searchRepository})
    : _searchRepository = searchRepository,
      super(const SearchState()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchClearRequested>(_onClearRequested);
  }
  final SearchRepository _searchRepository;

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query;

    if (query.isEmpty) {
      emit(state.copyWith(query: query, items: const StatusInitial()));
      return;
    }

    emit(
      state.copyWith(
        query: query,
        items: StatusLoading(previousValue: state.items.value),
      ),
    );

    try {
      final items = await _searchRepository.searchMedia(query);
      emit(state.copyWith(items: StatusSuccess(items)));
    } on Exception catch (error) {
      LoggerService.api.severe('Failed to search media', error);
      emit(state.copyWith(items: const StatusError('Failed to search media')));
    }
  }

  void _onClearRequested(
    SearchClearRequested event,
    Emitter<SearchState> emit,
  ) {
    emit(const SearchState());
  }
}
