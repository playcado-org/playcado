import 'package:playcado/media/models/media_item.dart';

abstract class MediaUrlService {
  String getImageUrl(
    String itemId, {
    int? maxWidth,
    int? maxHeight,
    int? quality,
  });
  String getBackdropUrl(
    String itemId, {
    int? maxWidth,
    int? maxHeight,
    int? quality,
  });
  String getStreamUrl(String itemId);
  String getDownloadUrl(String itemId, {int? maxHeight});
  String generateTranscodeUrl({
    required String itemId,
    required String mediaSourceId,
  });
}

extension MediaUrlServiceExtensions on MediaUrlService {
  /// Gets the best backdrop URL for an item, falling back to the primary image for photos/videos
  /// and the series backdrop for episodes.
  String getItemBackdropUrl(
    MediaItem item, {
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) {
    if (item.type == MediaItemType.photo || item.type == MediaItemType.video) {
      return getImageUrl(
        item.id,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );
    }

    final backdropId =
        (item.type == MediaItemType.episode && item.seriesId != null)
        ? item.seriesId!
        : item.id;
    return getBackdropUrl(
      backdropId,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: quality,
    );
  }

  /// Gets the best poster/thumbnail URL for an item.
  /// If [isLandscape] is true, it attempts to get a
  /// backdrop-style image or episode grab.
  String getItemImageUrl(
    MediaItem item, {
    bool isLandscape = false,
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) {
    if (isLandscape) {
      final usePrimary =
          item.type == MediaItemType.photo || item.type == MediaItemType.video;
      return (item.type == MediaItemType.episode || usePrimary)
          ? getImageUrl(
              item.id,
              maxWidth: maxWidth,
              maxHeight: maxHeight,
              quality: quality,
            )
          : getBackdropUrl(
              item.id,
              maxWidth: maxWidth,
              maxHeight: maxHeight,
              quality: quality,
            );
    } else {
      final posterId =
          (item.type == MediaItemType.episode && item.seriesId != null)
          ? item.seriesId!
          : item.id;
      return getImageUrl(
        posterId,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );
    }
  }
}
