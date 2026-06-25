part of 'downloads_screen.dart';

class _DownloadsGrid extends StatelessWidget {
  const _DownloadsGrid({required this.filterType});
  final MediaItemType filterType;

  @override
  Widget build(BuildContext context) {
    final items = context.select<DownloadsBloc, List<DownloadedMediaItem>>(
      (b) => b.state.offlineLibrary
          .where((d) => d.media.type == filterType)
          .toList(),
    );

    if (items.isEmpty) {
      return _EmptyState(
        icon: filterType == MediaItemType.movie
            ? PlaycadoIcons.movie
            : PlaycadoIcons.tv,
        message: filterType == MediaItemType.movie
            ? context.l10n.noDownloadedMovies
            : context.l10n.noDownloadedEpisodes,
        subMessage: context.l10n.downloadedContentIsAvailableOffline,
        showBrowseButton: true,
      );
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
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _DownloadPoster(item: items[index]);
      },
    );
  }
}
