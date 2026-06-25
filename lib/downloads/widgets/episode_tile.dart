part of '../views/downloads_screen.dart';

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.item});
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

    return Card(
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
                  child: imageUrl.isNotEmpty
                      ? PlaycadoNetworkImage(
                          imageUrl: imageUrl,
                          errorWidget: (context, url, error) => ColoredBox(
                            color: colorScheme.surfaceContainerHighest,
                            child: const PlaycadoIcon(
                              PlaycadoIcons.imageNotFound,
                            ),
                          ),
                        )
                      : ColoredBox(
                          color: colorScheme.surfaceContainerHighest,
                          child: const PlaycadoIcon(PlaycadoIcons.tv),
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
    );
  }
}
