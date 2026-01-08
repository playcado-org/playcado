import 'package:flutter/material.dart';
import 'package:playcado/l10n/app_localizations.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/widgets/widgets.dart';

class MediaDetailsOverview extends StatelessWidget {
  const MediaDetailsOverview({
    required this.item,
    super.key,
    this.nextEpisode,
    this.isLoading = false,
  });
  final MediaItem item;
  final MediaItem? nextEpisode;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const _MediaDetailsOverviewShimmer();
    }

    // Use specific item metadata if it is an episode (playing) or next up
    final displayItem =
        (item.type == MediaItemType.series && nextEpisode != null)
        ? nextEpisode
        : item;
    final overviewText = displayItem?.overview;

    if (overviewText == null || overviewText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayItem case final di?
            when di.type == MediaItemType.episode) ...[
          Text(
            'S${di.parentIndexNumber} E${di.indexNumber} - ${di.name}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
        ] else ...[
          Text(
            l10n.overview,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          overviewText,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _MediaDetailsOverviewShimmer extends StatelessWidget {
  const _MediaDetailsOverviewShimmer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleHeight = theme.textTheme.titleMedium?.fontSize ?? 20.0;
    final bodyFontSize = theme.textTheme.bodyLarge?.fontSize ?? 16.0;
    const bodyHeightMultiplier = 1.5;
    final bodyLineHeight = bodyFontSize * bodyHeightMultiplier;
    final lineGap = bodyLineHeight - bodyFontSize;

    return PlaycadoShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 180,
            height: titleHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: bodyFontSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: lineGap),
          Container(
            width: double.infinity,
            height: bodyFontSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: lineGap),
          Container(
            width: 240,
            height: bodyFontSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
