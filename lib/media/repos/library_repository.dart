import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:playcado/core/retry.dart';
import 'package:playcado/media/data/media_remote_data_source.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/services/logger_service.dart';

class LibraryRepository {
  LibraryRepository({required MediaRemoteDataSource dataSource})
    : _dataSource = dataSource;
  final MediaRemoteDataSource _dataSource;

  Future<String?> _getUserId() => _dataSource.getCurrentUserId();

  Future<List<MediaItem>> getMovies({
    int startIndex = 0,
    int limit = 20,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
  }) async {
    LoggerService.api.info(
      'Fetching movies: Start=$startIndex, Limit=$limit, Sort=$sortBy/$sortOrder',
    );
    final currentUserId = await _getUserId();
    if (currentUserId == null) {
      throw Exception('Unable to get current user');
    }

    return retryWithBackoff(
      () async {
        final items = await _dataSource.fetchItems(
          userId: currentUserId,
          startIndex: startIndex,
          limit: limit,
          includeItemTypes: [BaseItemKind.movie],
          recursive: true,
          sortBy: [_parseSortBy(sortBy)],
          sortOrder: [
            if (sortOrder == 'Ascending')
              SortOrder.ascending
            else
              SortOrder.descending,
          ],
          fields: [
            ItemFields.overview,
            ItemFields.mediaSources,
          ],
        );
        LoggerService.api.info('Fetched ${items.length} movies');
        return items;
      },
      label: 'getMovies',
    );
  }

  Future<MediaItem> getItem(String id) async {
    final currentUserId = await _getUserId();
    if (currentUserId == null) {
      throw Exception('Unable to get current user');
    }

    return retryWithBackoff(
      () async {
        final items = await _dataSource.fetchItems(
          userId: currentUserId,
          ids: [id],
          fields: [
            ItemFields.overview,
            ItemFields.mediaSources,
            ItemFields.people,
            ItemFields.chapters,
            ItemFields.childCount,
          ],
        );

        final item = items.firstOrNull;
        if (item == null) throw Exception('Item not found');
        return item;
      },
      label: 'getItem($id)',
    );
  }

  Future<List<MediaItem>> getTvShows({
    int startIndex = 0,
    int limit = 20,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
  }) async {
    LoggerService.api.info(
      'Fetching TV Shows: Start=$startIndex, Limit=$limit, Sort=$sortBy/$sortOrder',
    );
    final currentUserId = await _getUserId();
    if (currentUserId == null) {
      throw Exception('Unable to get current user');
    }

    return retryWithBackoff(
      () async {
        final items = await _dataSource.fetchItems(
          userId: currentUserId,
          startIndex: startIndex,
          limit: limit,
          includeItemTypes: [BaseItemKind.series],
          recursive: true,
          sortBy: [_parseSortBy(sortBy)],
          sortOrder: [
            if (sortOrder == 'Ascending')
              SortOrder.ascending
            else
              SortOrder.descending,
          ],
          fields: [
            ItemFields.overview,
            ItemFields.mediaSources,
            ItemFields.childCount,
          ],
        );
        LoggerService.api.info('Fetched ${items.length} TV shows');
        return items;
      },
      label: 'getTvShows',
    );
  }

  Future<List<MediaItem>> getLatestTvShows() async {
    LoggerService.api.info('Fetching latest TV shows');
    final currentUserId = await _getUserId();
    if (currentUserId == null) {
      throw Exception('Unable to get current user');
    }

    return retryWithBackoff(
      () async {
        final items = await _dataSource.fetchLatestMedia(
          userId: currentUserId,
          limit: 20,
          includeItemTypes: [BaseItemKind.series],
          fields: [
            ItemFields.overview,
            ItemFields.mediaSources,
            ItemFields.childCount,
          ],
        );
        LoggerService.api.info('Fetched ${items.length} latest TV shows');
        return items;
      },
      label: 'getLatestTvShows',
    );
  }

  Future<List<MediaItem>> getLatestMovies() async {
    LoggerService.api.info('Fetching latest Movies');
    final currentUserId = await _getUserId();
    if (currentUserId == null) {
      throw Exception('Unable to get current user');
    }

    return retryWithBackoff(
      () async {
        final items = await _dataSource.fetchLatestMedia(
          userId: currentUserId,
          limit: 20,
          includeItemTypes: [BaseItemKind.movie],
          fields: [
            ItemFields.overview,
            ItemFields.mediaSources,
            ItemFields.childCount,
          ],
        );
        LoggerService.api.info('Fetched ${items.length} latest movies');
        return items;
      },
      label: 'getLatestMovies',
    );
  }

  Future<List<MediaItem>> getResumeItems() async {
    LoggerService.api.info('Fetching Resume items');
    final currentUserId = await _getUserId();
    if (currentUserId == null) {
      throw Exception('Unable to get current user');
    }

    return retryWithBackoff(
      () async {
        final items = await _dataSource.fetchItems(
          userId: currentUserId,
          limit: 20,
          recursive: true,
          filters: [ItemFilter.isResumable],
          sortBy: [ItemSortBy.datePlayed],
          sortOrder: [SortOrder.descending],
          includeItemTypes: [BaseItemKind.movie, BaseItemKind.episode],
          fields: [
            ItemFields.overview,
            ItemFields.mediaSources,
            ItemFields.people,
            ItemFields.chapters,
          ],
        );
        LoggerService.api.info('Fetched ${items.length} resume items');
        return items;
      },
      label: 'getResumeItems',
    );
  }

  Future<List<MediaItem>> getNextUpItems() async {
    LoggerService.api.info('Fetching Next Up items');
    final currentUserId = await _getUserId();
    if (currentUserId == null) {
      throw Exception('Unable to get current user');
    }

    return retryWithBackoff(
      () async {
        final items = await _dataSource.fetchNextUp(
          userId: currentUserId,
          limit: 20,
          fields: [
            ItemFields.overview,
            ItemFields.mediaSources,
            ItemFields.people,
            ItemFields.chapters,
            ItemFields.childCount,
          ],
        );

        LoggerService.api.info('Fetched ${items.length} next up items');

        final uniqueSeriesMap = <String, MediaItem>{};
        for (final item in items) {
          if (item.seriesId != null && item.seriesName != null) {
            final seriesId = item.seriesId!;
            if (!uniqueSeriesMap.containsKey(seriesId)) {
              uniqueSeriesMap[seriesId] = item;
            }
          } else {
            final id = item.id;
            if (!uniqueSeriesMap.containsKey(id)) {
              uniqueSeriesMap[id] = item;
            }
          }
        }

        return uniqueSeriesMap.values.toList();
      },
      label: 'getNextUpItems',
    );
  }

  Future<MediaItem?> getNextEpisode(String seriesId) async {
    try {
      LoggerService.api.info('Fetching Next Episode for Series: $seriesId');
      final currentUserId = await _getUserId();
      if (currentUserId == null) return null;

      final items = await _dataSource.fetchNextUp(
        userId: currentUserId,
        seriesId: seriesId,
        limit: 1,
        fields: [
          ItemFields.overview,
          ItemFields.mediaSources,
          ItemFields.people,
          ItemFields.chapters,
        ],
      );

      if (items.isEmpty) return null;
      return items.first;
    } on Exception catch (e, s) {
      LoggerService.api.severe('Error fetching next episode', e, s);
      return null;
    }
  }

  Future<MediaItem?> getFirstEpisode(String seriesId) async {
    try {
      LoggerService.api.info('Fetching First Episode for Series: $seriesId');

      final seasons = await getSeasons(seriesId);
      if (seasons.isEmpty) return null;

      final regularSeasons = seasons
          .where((s) => (s.indexNumber ?? 0) > 0)
          .toList();
      final seasonToUse = regularSeasons.isNotEmpty
          ? regularSeasons.first
          : seasons.first;

      final episodes = await getEpisodes(
        seriesId: seriesId,
        seasonId: seasonToUse.id,
      );

      return episodes.isEmpty ? null : episodes.first;
    } on Exception catch (e, s) {
      LoggerService.api.severe('Error fetching first episode', e, s);
      return null;
    }
  }

  Future<List<MediaItem>> getSeasons(String seriesId) async {
    LoggerService.api.info('Fetching seasons for series: $seriesId');
    final currentUserId = await _getUserId();
    if (currentUserId == null) {
      throw Exception('Unable to get current user');
    }

    return retryWithBackoff(
      () async {
        final items = await _dataSource.fetchSeasons(
          userId: currentUserId,
          seriesId: seriesId,
          fields: [ItemFields.overview],
        );
        LoggerService.api.info('Fetched ${items.length} seasons');
        return items;
      },
      label: 'getSeasons($seriesId)',
    );
  }

  Future<List<MediaItem>> getEpisodes({
    required String seriesId,
    required String seasonId,
  }) async {
    LoggerService.api.info(
      'Fetching episodes for Season: $seasonId (Series: $seriesId)',
    );
    final currentUserId = await _getUserId();
    if (currentUserId == null) {
      throw Exception('Unable to get current user');
    }

    return retryWithBackoff(
      () async {
        final items = await _dataSource.fetchEpisodes(
          userId: currentUserId,
          seriesId: seriesId,
          seasonId: seasonId,
          fields: [
            ItemFields.overview,
            ItemFields.mediaSources,
            ItemFields.people,
            ItemFields.chapters,
          ],
        );
        LoggerService.api.info('Fetched ${items.length} episodes');
        return items;
      },
      label: 'getEpisodes($seasonId)',
    );
  }

  Future<List<MediaItem>> getLibraries() async {
    LoggerService.api.info('Fetching user libraries');
    final currentUserId = await _getUserId();
    if (currentUserId == null) {
      throw Exception('Unable to get current user');
    }

    return retryWithBackoff(
      () async {
        final items = await _dataSource.fetchViews(userId: currentUserId);
        LoggerService.api.info('Fetched ${items.length} libraries');
        return items;
      },
      label: 'getLibraries',
    );
  }

  Future<List<MediaItem>> getLibraryItems({
    required String parentId,
    String? collectionType,
    int startIndex = 0,
    int limit = 20,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
  }) async {
    LoggerService.api.info(
      'Fetching items for library $parentId: Start=$startIndex, Limit=$limit, Sort=$sortBy/$sortOrder',
    );
    final currentUserId = await _getUserId();
    if (currentUserId == null) {
      throw Exception('Unable to get current user');
    }

    return retryWithBackoff(
      () async {
        final items = await _dataSource.fetchItems(
          userId: currentUserId,
          parentId: parentId,
          startIndex: startIndex,
          limit: limit,
          recursive: true,
          sortBy: [_parseSortBy(sortBy)],
          sortOrder: [
            if (sortOrder == 'Ascending')
              SortOrder.ascending
            else
              SortOrder.descending,
          ],
          fields: [
            ItemFields.overview,
            ItemFields.mediaSources,
            ItemFields.childCount,
          ],
        );

        final filteredItems = items
            .where(
              (item) =>
                  item.type != MediaItemType.folder &&
                  item.type != MediaItemType.collectionFolder,
            )
            .toList();

        LoggerService.api.info(
          'Fetched ${items.length} items from library '
          '$parentId (filtered to ${filteredItems.length})',
        );
        return filteredItems;
      },
      label: 'getLibraryItems($parentId)',
    );
  }

  ItemSortBy _parseSortBy(String sortBy) {
    switch (sortBy) {
      case 'PremiereDate':
        return ItemSortBy.premiereDate;
      case 'DateCreated':
        return ItemSortBy.dateCreated;
      case 'SortName':
      default:
        return ItemSortBy.sortName;
    }
  }
}
