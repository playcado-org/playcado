import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/status_wrapper.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/search/repositories/search_repository.dart';
import 'package:playcado/services/logger_service.dart';
import 'package:playcado/services/preferences_service.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({
    required PreferencesService preferencesService,
    required SearchRepository searchRepository,
  }) : _preferencesService = preferencesService,
       _searchRepository = searchRepository,
       super(const SearchState()) {
    on<SearchClearRequested>(_onClearRequested);
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchRecentSearchesCleared>(_onRecentSearchesCleared);
    on<SearchRecentSearchRemoved>(_onRecentSearchRemoved);
    on<SearchResultTapped>(_onResultTapped);
    on<_SearchRecentSearchesRequested>(
      (event, emit) => _loadRecentSearches(emit),
    );
    add(const _SearchRecentSearchesRequested());
  }
  final PreferencesService _preferencesService;
  final SearchRepository _searchRepository;

  Future<void> _loadRecentSearches(Emitter<SearchState> emit) async {
    final searches = await _preferencesService.getRecentSearches();
    emit(state.copyWith(recentSearches: searches));
  }

  void _onClearRequested(
    SearchClearRequested event,
    Emitter<SearchState> emit,
  ) {
    emit(const SearchState());
  }

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
      final recentSearches = _recentSearchesWithAdded(query);
      emit(
        state.copyWith(
          items: StatusSuccess(items),
          recentSearches: recentSearches,
        ),
      );
      _preferencesService.saveRecentSearches(recentSearches);
    } on Exception catch (error) {
      LoggerService.api.severe('Failed to search media', error);
      emit(state.copyWith(items: const StatusError('Failed to search media')));
    }
  }

  List<String> _recentSearchesWithAdded(String query) {
    final searches = List<String>.from(state.recentSearches);
    searches.remove(query);
    searches.insert(0, query);
    return searches.take(10).toList();
  }

  void _onRecentSearchRemoved(
    SearchRecentSearchRemoved event,
    Emitter<SearchState> emit,
  ) {
    final searches = List<String>.from(state.recentSearches);
    searches.remove(event.query);
    emit(state.copyWith(recentSearches: searches));
    _preferencesService.saveRecentSearches(searches);
  }

  void _onRecentSearchesCleared(
    SearchRecentSearchesCleared event,
    Emitter<SearchState> emit,
  ) {
    emit(state.copyWith(recentSearches: const []));
    _preferencesService.saveRecentSearches(const []);
  }

  Future<void> _onResultTapped(
    SearchResultTapped event,
    Emitter<SearchState> emit,
  ) async {
    final searches = List<String>.from(state.recentSearches);
    if (searches.isNotEmpty && searches.first == state.query) {
      searches.removeAt(0);
    }
    searches.remove(event.mediaName);
    searches.insert(0, event.mediaName);
    final trimmed = searches.take(10).toList();
    emit(state.copyWith(recentSearches: trimmed));
    await _preferencesService.saveRecentSearches(trimmed);
  }
}

class _SearchRecentSearchesRequested extends SearchEvent {
  const _SearchRecentSearchesRequested();
}
