import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:playcado/app_router/app_router.dart';
import 'package:playcado/downloads/bloc/downloads_bloc.dart';
import 'package:playcado/downloads/models/downloaded_media_item.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/services/media_url/media_url_service.dart';
import 'package:playcado/widgets/widgets.dart';
import 'package:shimmer/shimmer.dart';

/// A widget that displays a media poster with a hero transition.
class MediaPoster extends StatelessWidget {
  const MediaPoster({
    super.key,
    this.item,
    this.heroTag,
    this.isLandscape = false,
    this.customCacheWidth,
    this.customCacheHeight,
    this.isLoading = false,
    this.onTap,
    this.width,
  }) : assert(
         isLoading || item != null,
         'Either isLoading must be true or item must be provided',
       );
  final MediaItem? item;
  final String? heroTag;
  final bool isLandscape;
  final int? customCacheWidth;
  final int? customCacheHeight;
  final bool isLoading;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading || item == null) {
      return _buildSkeleton(context);
    }

    final mediaItem = item!;
    final urlGenerator = context.read<MediaUrlService>();
    final effectiveTag = heroTag ?? mediaItem.heroTag();

    final title = mediaItem.type == MediaItemType.episode
        ? (mediaItem.seriesName ?? mediaItem.name)
        : mediaItem.name;

    final subtitle = mediaItem.displaySubtitle;

    final imgUrl = urlGenerator.getItemImageUrl(
      mediaItem,
      isLandscape: isLandscape,
      maxWidth: customCacheWidth ?? (isLandscape ? 800 : 400),
      quality: 80,
    );

    final localPosterPath = _findLocalPosterPath(context, mediaItem);

    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: () {
          onTap?.call();
          unawaited(
            context.push(
              AppRouter.detailsPath,
              extra: {'item': mediaItem, 'heroTag': effectiveTag},
            ),
          );
        },
        child: RepaintBoundary(
          child: Hero(
            tag: effectiveTag,
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: PlaycadoImage(
                        imageUrl: imgUrl,
                        localFile: localPosterPath,
                        width: double.infinity,
                        memCacheWidth:
                            customCacheWidth ?? (isLandscape ? 800 : 400),
                        memCacheHeight: customCacheHeight,
                        placeholder: (context, url) => ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: PlaycadoIcon(
                              isLandscape
                                  ? PlaycadoIcons.image
                                  : PlaycadoIcons.movie,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: PlaycadoIcon(
                            PlaycadoIcons.imageNotFound,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String? _findLocalPosterPath(BuildContext context, MediaItem item) {
    try {
      final match = context
          .read<DownloadsBloc>()
          .state
          .offlineLibrary
          .cast<DownloadedMediaItem?>()
          .firstWhere((d) => d?.media.id == item.id, orElse: () => null);
      if (match?.localPosterPath case final path?
          when File(path).existsSync()) {
        return path;
      }
    } catch (_) {}
    return null;
  }

  Widget _buildSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: width != null ? width! * 0.7 : 100,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: width != null ? width! * 0.4 : 60,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
