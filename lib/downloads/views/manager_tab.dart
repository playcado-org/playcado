part of 'downloads_screen.dart';

class ManagerTab extends StatelessWidget {
  const ManagerTab();

  @override
  Widget build(BuildContext context) {
    final active = context.select<DownloadsBloc, List<ActiveDownload>>(
      (b) => b.state.activeDownloads,
    );
    final completed =
        context.select<DownloadsBloc, List<DownloadedMediaItem>>(
          (b) => b.state.offlineLibrary,
        )..sort(
          (a, b) => b.downloadedAt.millisecondsSinceEpoch.compareTo(
            a.downloadedAt.millisecondsSinceEpoch,
          ),
        );
    if (completed.length > 10) completed.length = 10;

    final hasActive = active.isNotEmpty;
    final hasCompleted = completed.isNotEmpty;

    if (!hasActive && !hasCompleted) {
      return _EmptyState(
        icon: PlaycadoIcons.download,
        message: context.l10n.noDownloadsYet,
        subMessage: context.l10n.downloadedContentIsAvailableOffline,
        showBrowseButton: true,
      );
    }

    final playerActive = context.select<PlayerBloc, bool>(
      (b) => b.state.isActive,
    );
    final bottomPadding =
        MediaQuery.paddingOf(context).bottom + 10 + (playerActive ? 70 : 0);

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      children: [
        if (hasActive) ...[
          _SectionHeader(title: context.l10n.active),
          const SizedBox(height: 8),
          ...active.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActiveDownloadCard(itemId: item.media.id),
            ),
          ),
        ],
        if (hasCompleted) ...[
          _SectionHeader(title: context.l10n.completed),
          const SizedBox(height: 8),
          ...completed.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CompletedDownloadCard(item: item, isOfflineMode: false),
            ),
          ),
        ],
      ],
    );
  }
}
