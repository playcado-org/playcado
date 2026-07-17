import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:playcado/core/retry.dart';
import 'package:playcado/media/data/media_remote_data_source.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/services/logger_service.dart';

class SearchRepository {
  SearchRepository({required MediaRemoteDataSource dataSource})
    : _dataSource = dataSource;
  final MediaRemoteDataSource _dataSource;

  Future<List<MediaItem>> searchMedia(String query) async {
    if (query.trim().isEmpty) return [];

    LoggerService.api.info('Searching media with query: $query');

    final userId = await _dataSource.getCurrentUserId();
    if (userId == null) {
      throw Exception('Unable to get current user');
    }

    return retryWithBackoff(() async {
      final results = await Future.wait([
        _dataSource.fetchItems(
          userId: userId,
          searchTerm: query,
          limit: 50,
          recursive: true,
          includeItemTypes: [BaseItemKind.movie, BaseItemKind.series],
        ),
        _dataSource.fetchItems(
          userId: userId,
          searchTerm: query,
          limit: 50,
          recursive: true,
          includeItemTypes: [BaseItemKind.episode],
        ),
      ]);

      final queryLower = query.toLowerCase();

      final items = [...results[0], ...results[1]]
        ..sort((a, b) {
          final aName = a.name.toLowerCase();
          final bName = b.name.toLowerCase();

          final aExact = aName == queryLower;
          final bExact = bName == queryLower;
          if (aExact && !bExact) return -1;
          if (!aExact && bExact) return 1;

          final aStarts = aName.startsWith(queryLower);
          final bStarts = bName.startsWith(queryLower);
          if (aStarts && !bStarts) return -1;
          if (!aStarts && bStarts) return 1;

          int priority(MediaItemType? type) {
            switch (type) {
              case MediaItemType.movie:
                return 0;
              case MediaItemType.series:
                return 1;
              case MediaItemType.episode:
                return 2;
              case MediaItemType.season:
              case MediaItemType.collectionFolder:
              case MediaItemType.folder:
              case MediaItemType.photo:
              case MediaItemType.video:
              case MediaItemType.other:
              case null:
                return 3;
            }
          }

          final typeCompare = priority(a.type).compareTo(priority(b.type));
          if (typeCompare != 0) return typeCompare;

          return aName.compareTo(bName);
        });

      return items;
    }, label: 'searchMedia($query)');
  }
}
