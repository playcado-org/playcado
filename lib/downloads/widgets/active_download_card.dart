part of '../views/downloads_screen.dart';

class _ActiveDownloadCard extends StatelessWidget {
  const _ActiveDownloadCard({required this.item});
  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPaused = item.status == DownloadStatus.paused;
    final isError = item.status == DownloadStatus.error;
    final isDownloading = item.status == DownloadStatus.downloading;

    // Indeterminate if downloading but total size is unknown/0
    final isIndeterminate = isDownloading && item.totalBytes <= 0;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 60,
                    height: 90,
                    child: item.imageUrl != null
                        ? PlaycadoNetworkImage(
                            imageUrl: item.imageUrl!,
                            errorWidget: (context, url, error) => ColoredBox(
                              color: colorScheme.surfaceContainerHighest,
                              child: const PlaycadoIcon(
                                PlaycadoIcons.imageNotFound,
                              ),
                            ),
                          )
                        : ColoredBox(
                            color: colorScheme.surfaceContainerHighest,
                            child: const PlaycadoIcon(PlaycadoIcons.movie),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (item.progress > 0 && !isIndeterminate)
                              ? item.progress
                              : (isDownloading ? null : 0),
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          color: isError
                              ? colorScheme.error
                              : (isPaused
                                    ? colorScheme.secondary
                                    : colorScheme.primary),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Meta Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _getProgressText(context),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isError
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isDownloading && (item.networkSpeed ?? 0) > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                Formatters.formatSpeed(item.networkSpeed ?? 0),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (item.status == DownloadStatus.downloading ||
                    item.status == DownloadStatus.queued)
                  TextButton.icon(
                    onPressed: () {
                      context.read<DownloadsBloc>().add(
                        DownloadsPauseRequested(item.id),
                      );
                    },
                    icon: const PlaycadoIcon(PlaycadoIcons.pause),
                    label: Text(context.l10n.pause),
                  )
                else if (isPaused || isError)
                  TextButton.icon(
                    onPressed: () {
                      context.read<DownloadsBloc>().add(
                        DownloadsResumeRequested(item.id),
                      );
                    },
                    icon: const PlaycadoIcon(PlaycadoIcons.play),
                    label: Text(context.l10n.resume),
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    context.read<DownloadsBloc>().add(
                      DownloadsDeleteRequested(item.id),
                    );
                    SnackbarHelper.showInfo(
                      context,
                      context.l10n.downloadCancelled,
                    );
                  },
                  icon: const PlaycadoIcon(PlaycadoIcons.cancel),
                  label: Text(context.l10n.cancel),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getProgressText(BuildContext context) {
    switch (item.status) {
      case DownloadStatus.queued:
        return context.l10n.queued;
      case DownloadStatus.downloading:
        final percent = (item.progress * 100).toStringAsFixed(1);
        if (item.totalBytes > 0) {
          final current = Formatters.formatBytes(item.receivedBytes);
          final total = Formatters.formatBytes(item.totalBytes);
          return '$percent% • $current of $total';
        }
        return '$percent%';
      case DownloadStatus.paused:
        return context.l10n.paused;
      case DownloadStatus.error:
        return context.l10n.failed;
      case DownloadStatus.completed:
        return context.l10n.completed;
    }
  }
}
