import 'package:flutter/material.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/movie_details/views/movie_details_page.dart';
import 'package:playcado/series_details/views/series_details_page.dart';

class MediaDetailsPage extends StatelessWidget {
  const MediaDetailsPage({
    required this.item,
    required this.heroTag,
    super.key,
  });
  final MediaItem item;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    if (item.type == MediaItemType.series ||
        item.type == MediaItemType.episode) {
      return SeriesDetailsPage(item: item, heroTag: heroTag);
    } else {
      return MovieDetailsPage(item: item, heroTag: heroTag);
    }
  }
}
