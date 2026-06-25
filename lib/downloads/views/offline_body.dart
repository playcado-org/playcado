part of 'downloads_screen.dart';

class _OfflineBody extends StatelessWidget {
  const _OfflineBody();

  @override
  Widget build(BuildContext context) {
    final items = context.select<DownloadsBloc, List<DownloadedMediaItem>>(
      (b) => b.state.offlineLibrary,
    );
    if (items.isEmpty) {
      return _EmptyState(
        icon: PlaycadoIcons.download,
        message: context.l10n.noOfflineContent,
        subMessage: context.l10n.connectToYourServerToDownloadContent,
        showBrowseButton: false,
      );
    }

    final playerActive = context.select<PlayerBloc, bool>(
      (b) => b.state.isActive,
    );
    final bottomPadding =
        MediaQuery.paddingOf(context).bottom + 10 + (playerActive ? 70 : 0);

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _CompletedDownloadCard(item: items[index], isOfflineMode: true);
      },
    );
  }
}
