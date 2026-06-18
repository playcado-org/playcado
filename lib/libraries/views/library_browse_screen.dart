import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/media/repositories/library_repository.dart';
import 'package:playcado/paginated_media_list/bloc/paginated_media_list_bloc.dart';
import 'package:playcado/paginated_media_list/widgets/paginated_media_grid.dart';

class LibraryBrowseScreen extends StatelessWidget {
  const LibraryBrowseScreen({required this.library, super.key});
  final MediaItem library;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<LibraryRepository>();

    return BlocProvider<PaginatedMediaListBloc>(
      create: (context) => PaginatedMediaListBloc(
        fetcher:
            ({
              required startIndex,
              required limit,
              required sortBy,
              required sortOrder,
            }) => repo.getLibraryItems(
              parentId: library.id,
              collectionType: library.collectionType,
              startIndex: startIndex,
              limit: limit,
              sortBy: sortBy,
              sortOrder: sortOrder,
            ),
      )..add(PaginatedMediaListItemsFetched()),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: LibraryItemsGrid(title: library.name),
      ),
    );
  }
}

class LibraryItemsGrid extends StatelessWidget {
  const LibraryItemsGrid({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaginatedMediaListBloc, PaginatedMediaListState>(
      builder: (context, state) {
        return PaginatedMediaGrid(
          title: title,
          header: Text(title),
          items: state.items.value,
          isLoading: state.items.isLoading,
          isError: state.items.isError,
          hasReachedMax: state.hasReachedMax,
          sortBy: state.sortBy,
          sortOrder: state.sortOrder,
          dateSortLabel: context.l10n.dateCreated,
          onLoadMore: () {
            context.read<PaginatedMediaListBloc>().add(
              PaginatedMediaListMoreItemsFetched(),
            );
          },
          onRefresh: () async {
            context.read<PaginatedMediaListBloc>().add(
              PaginatedMediaListItemsFetched(),
            );
            await Future<void>.delayed(const Duration(milliseconds: 500));
          },
          onRetry: () {
            context.read<PaginatedMediaListBloc>().add(
              PaginatedMediaListItemsFetched(),
            );
          },
          onSortChanged: (sortBy, sortOrder) {
            context.read<PaginatedMediaListBloc>().add(
              PaginatedMediaListSortChanged(
                sortBy: sortBy,
                sortOrder: sortOrder,
              ),
            );
          },
        );
      },
    );
  }
}
