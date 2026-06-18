part of '../views/downloads_screen.dart';

class _SeriesHeader extends StatelessWidget {
  const _SeriesHeader({required this.seriesName, required this.episodes});
  final String seriesName;
  final List<DownloadItem> episodes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = episodes.first;
    final seasonCount = episodes.map((e) => e.parentIndexNumber).toSet().length;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 48,
            child: first.imageUrl != null
                ? PlaycadoNetworkImage(
                    imageUrl: first.imageUrl!,
                    errorWidget: (context, url, error) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const PlaycadoIcon(PlaycadoIcons.imageNotFound),
                    ),
                  )
                : ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const PlaycadoIcon(PlaycadoIcons.tv),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                seriesName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${episodes.length} ${episodes.length == 1 ? 'episode' : 'episodes'}'
                '${seasonCount > 1 ? ' • $seasonCount seasons' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
