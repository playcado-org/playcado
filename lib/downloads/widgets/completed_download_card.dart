part of '../views/downloads_screen.dart';

class _CompletedDownloadCard extends StatelessWidget {
  const _CompletedDownloadCard({
    required this.item,
    required this.isOfflineMode,
  });
  final DownloadedMediaItem item;
  final bool isOfflineMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final urlService = context.read<MediaUrlService>();
    final imageUrl = urlService.getImageUrl(item.media.id);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          unawaited(
            context.push(AppRouter.offlineMediaDetailPath, extra: item),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 50,
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
                              child: const PlaycadoIcon(
                                PlaycadoIcons.placeholderImage,
                              ),
                            ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const PlaycadoIcon(
                      PlaycadoIcons.play,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.media.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.totalBytes > 0)
                      Text(
                        Formatters.formatBytes(item.totalBytes),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isOfflineMode)
                IconButton(
                  onPressed: () {
                    context.read<DownloadsBloc>().add(
                      DownloadsDeleteRequested(item.id),
                    );
                    SnackbarHelper.showInfo(
                      context,
                      context.l10n.deletedItem(item.media.name),
                    );
                  },
                  icon: const PlaycadoIcon(PlaycadoIcons.trash),
                  color: colorScheme.error,
                  tooltip: context.l10n.delete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
