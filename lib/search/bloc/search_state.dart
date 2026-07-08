part of 'search_bloc.dart';

class SearchState extends Equatable {
  const SearchState({
    this.items = const StatusInitial(),
    this.query = '',
    this.recentSearches = const [],
    this.userId = '',
  });
  final StatusWrapper<List<MediaItem>> items;
  final String query;
  final List<String> recentSearches;
  final String userId;

  SearchState copyWith({
    StatusWrapper<List<MediaItem>>? items,
    String? query,
    List<String>? recentSearches,
    String? userId,
  }) {
    return SearchState(
      items: items ?? this.items,
      query: query ?? this.query,
      recentSearches: recentSearches ?? this.recentSearches,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [items, query, recentSearches, userId];
}
