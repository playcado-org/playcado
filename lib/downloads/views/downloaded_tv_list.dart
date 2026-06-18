part of 'downloads_screen.dart';

class _DownloadedTvList extends StatelessWidget {
  const _DownloadedTvList();

  @override
  Widget build(BuildContext context) {
    final episodes = context.select<DownloadsBloc, List<DownloadItem>>(
      (b) => b.state.completedDownloads
          .where((d) => d.type == MediaItemType.episode)
          .toList(),
    );

    if (episodes.isEmpty) {
      return _EmptyState(
        icon: PlaycadoIcons.tv,
        message: context.l10n.noDownloadedEpisodes,
        subMessage: context.l10n.downloadedContentIsAvailableOffline,
        showBrowseButton: true,
      );
    }

    final grouped = <String, List<DownloadItem>>{};
    for (final ep in episodes) {
      final key = ep.seriesName ?? ep.name;
      grouped.putIfAbsent(key, () => []).add(ep);
    }

    for (final group in grouped.values) {
      group.sort((a, b) {
        final sa = a.parentIndexNumber ?? 0;
        final sb = b.parentIndexNumber ?? 0;
        if (sa != sb) return sa.compareTo(sb);
        final ea = a.indexNumber ?? 0;
        final eb = b.indexNumber ?? 0;
        return ea.compareTo(eb);
      });
    }

    final sortedKeys = grouped.keys.toList()..sort();

    final playerActive = context.select<PlayerBloc, bool>(
      (b) => b.state.isActive,
    );
    final bottomPadding =
        MediaQuery.paddingOf(context).bottom + 10 + (playerActive ? 70 : 0);

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      children: [
        for (final seriesName in sortedKeys) ...[
          _SeriesHeader(seriesName: seriesName, episodes: grouped[seriesName]!),
          const SizedBox(height: 8),
          for (final ep in grouped[seriesName]!) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _EpisodeTile(item: ep),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
