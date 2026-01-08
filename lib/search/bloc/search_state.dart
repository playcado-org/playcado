part of 'search_bloc.dart';

class SearchState extends Equatable {
  const SearchState({
    this.items = const StatusInitial(),
    this.query = '',
  });
  final StatusWrapper<List<MediaItem>> items;
  final String query;

  SearchState copyWith({
    StatusWrapper<List<MediaItem>>? items,
    String? query,
  }) {
    return SearchState(
      items: items ?? this.items,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [items, query];
}
