part of 'search_bloc.dart';

class SearchState extends Equatable {
  const SearchState({
    this.items = const StatusInitial(),
    this.query = '',
    this.recentSearches = const [],
  });
  final StatusWrapper<List<MediaItem>> items;
  final String query;
  final List<String> recentSearches;

  SearchState copyWith({
    StatusWrapper<List<MediaItem>>? items,
    String? query,
    List<String>? recentSearches,
  }) {
    return SearchState(
      items: items ?? this.items,
      query: query ?? this.query,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }

  @override
  List<Object?> get props => [items, query, recentSearches];
}
