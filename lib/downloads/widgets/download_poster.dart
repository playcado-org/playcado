part of '../views/downloads_screen.dart';

class _DownloadPoster extends StatelessWidget {
  const _DownloadPoster({required this.item});
  final DownloadedMediaItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urlService = context.read<MediaUrlService>();
    final imageUrl = urlService.getImageUrl(item.media.id);

    return Semantics(
      button: true,
      label: item.media.name,
      child: GestureDetector(
        onTap: () {
          unawaited(
            context.push(AppRouter.offlineMediaDetailPath, extra: item),
          );
        },
        child: RepaintBoundary(
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
                    imageUrl: imageUrl,
                    localFile: item.localPosterPath,
                    width: double.infinity,
                    memCacheWidth: 240,
                    memCacheHeight: 360,
                    placeholder: (context, url) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: PlaycadoIcon(
                          PlaycadoIcons.movie,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.2,
                          ),
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
                item.media.productionYear != null
                    ? item.media.name.replaceAll(
                        ' (${item.media.productionYear})',
                        '',
                      )
                    : item.media.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              if (item.media.productionYear case final year?)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    year,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
