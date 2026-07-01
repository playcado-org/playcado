part of 'downloads_screen.dart';

class DownloadedTvGrid extends StatelessWidget {
  const DownloadedTvGrid();

  @override
  Widget build(BuildContext context) {
    final (:List<DownloadedMediaItem> episodes, :bool isLoading) = context
        .select(
          (DownloadsBloc bloc) => (
            isLoading: bloc.state.isLoading,
            episodes: bloc.state.offlineLibrary
                .where((d) => d.media.type == MediaItemType.episode)
                .toList(),
          ),
        );

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (episodes.isEmpty) {
      return _EmptyState(
        icon: PlaycadoIcons.tv,
        message: context.l10n.noDownloadedEpisodes,
        subMessage: context.l10n.downloadedContentIsAvailableOffline,
        showBrowseButton: true,
      );
    }

    final seriesMap = <String, _SeriesGroup>{};
    for (final ep in episodes) {
      final key = ep.media.seriesId ?? ep.media.seriesName ?? ep.media.name;
      final group = seriesMap.putIfAbsent(
        key,
        () => _SeriesGroup(
          seriesId: ep.media.seriesId ?? ep.media.id,
          seriesName: ep.media.seriesName ?? ep.media.name,
          productionYear: ep.media.productionYear,
          episodes: [],
        ),
      );
      group.episodes.add(ep);
    }

    for (final group in seriesMap.values) {
      final firstEp = group.episodes.firstOrNull;
      if (firstEp?.localPosterPath case final posterPath?) {
        final dir = Directory(posterPath).parent;
        final seriesPosterPath =
            '${dir.path}/${group.seriesId}_series_poster.jpg';
        if (File(seriesPosterPath).existsSync()) {
          group.localSeriesPosterPath = seriesPosterPath;
        }
      }
    }

    final sortedGroups = seriesMap.values.toList()
      ..sort((a, b) => a.seriesName.compareTo(b.seriesName));

    for (final group in sortedGroups) {
      group.episodes.sort((a, b) {
        final sa = a.media.parentIndexNumber ?? 0;
        final sb = b.media.parentIndexNumber ?? 0;
        if (sa != sb) return sa.compareTo(sb);
        final ea = a.media.indexNumber ?? 0;
        final eb = b.media.indexNumber ?? 0;
        return ea.compareTo(eb);
      });
    }

    final playerActive = context.select<PlayerBloc, bool>(
      (b) => b.state.isActive,
    );
    final bottomPadding =
        MediaQuery.paddingOf(context).bottom + 10 + (playerActive ? 70 : 0);

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.50,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: sortedGroups.length,
      itemBuilder: (context, index) {
        return _SeriesPoster(group: sortedGroups[index]);
      },
    );
  }
}

class _SeriesGroup {
  final String seriesId;
  final String seriesName;
  final String? productionYear;
  final List<DownloadedMediaItem> episodes;
  String? localSeriesPosterPath;

  _SeriesGroup({
    required this.seriesId,
    required this.seriesName,
    this.productionYear,
    required this.episodes,
  });
}

class _SeriesPoster extends StatelessWidget {
  const _SeriesPoster({required this.group});
  final _SeriesGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urlService = context.read<MediaUrlService>();
    final imageUrl = urlService.getImageUrl(group.seriesId);

    return Semantics(
      button: true,
      label: group.seriesName,
      child: GestureDetector(
        onTap: () {
          unawaited(
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DownloadedSeriesDetailsPage(
                  seriesId: group.seriesId,
                  seriesName: group.seriesName,
                ),
              ),
            ),
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
                    localFile: group.localSeriesPosterPath,
                    width: double.infinity,
                    memCacheWidth: 240,
                    memCacheHeight: 360,
                    placeholder: (context, url) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: PlaycadoIcon(
                          PlaycadoIcons.tv,
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
                group.seriesName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              if (group.productionYear case final year?)
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
