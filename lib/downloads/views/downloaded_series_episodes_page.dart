import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:playcado/app_router/app_router.dart';
import 'package:playcado/core/formatters.dart';
import 'package:playcado/downloads/bloc/downloads_bloc.dart';
import 'package:playcado/downloads/models/downloaded_media_item.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/services/media_url/media_url_service.dart';
import 'package:playcado/widgets/widgets.dart';

class DownloadedSeriesEpisodesPage extends StatelessWidget {
  const DownloadedSeriesEpisodesPage({
    required this.seriesId,
    required this.seriesName,
    super.key,
  });

  final String seriesId;
  final String seriesName;

  @override
  Widget build(BuildContext context) {
    final episodes = context.select<DownloadsBloc, List<DownloadedMediaItem>>(
      (b) =>
          b.state.offlineLibrary
              .where(
                (d) =>
                    d.media.type == MediaItemType.episode &&
                    (d.media.seriesId == seriesId ||
                        d.media.seriesName == seriesName),
              )
              .toList()
            ..sort((a, b) {
              final sa = a.media.parentIndexNumber ?? 0;
              final sb = b.media.parentIndexNumber ?? 0;
              if (sa != sb) return sa.compareTo(sb);
              final ea = a.media.indexNumber ?? 0;
              final eb = b.media.indexNumber ?? 0;
              return ea.compareTo(eb);
            }),
    );

    return Scaffold(
      appBar: AppBar(title: Text(seriesName), centerTitle: false),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: episodes.length,
        itemBuilder: (context, index) {
          return _EpisodeCard(item: episodes[index]);
        },
      ),
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({required this.item});
  final DownloadedMediaItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final urlService = context.read<MediaUrlService>();
    final imageUrl = urlService.getImageUrl(item.media.id);

    final season =
        item.media.parentIndexNumber?.toString().padLeft(2, '0') ?? '??';
    final episode = item.media.indexNumber?.toString().padLeft(2, '0') ?? '??';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainer,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            unawaited(
              context.push(AppRouter.offlineMediaDetailPath, extra: item),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: PlaycadoImage(
                      imageUrl: imageUrl,
                      localFile: item.localPosterPath,
                      errorWidget: (context, url, error) => ColoredBox(
                        color: colorScheme.surfaceContainerHighest,
                        child: const PlaycadoIcon(PlaycadoIcons.imageNotFound),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'S$season E$episode',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          if (item.totalBytes > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              Formatters.formatBytes(item.totalBytes),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.media.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const PlaycadoIcon(
                  PlaycadoIcons.arrowRight,
                  color: Colors.grey,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
