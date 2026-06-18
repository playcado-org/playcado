import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:playcado/app_router/app_router.dart';
import 'package:playcado/auth/bloc/auth_bloc.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/core/formatters.dart';
import 'package:playcado/downloads/bloc/downloads_bloc.dart';
import 'package:playcado/downloads/models/download_item.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/widgets/widgets.dart';
import 'package:playcado/downloads/views/offline_media_detail_page.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isOfflineMode = context.select<AuthBloc, bool>(
      (b) => b.state.isOfflineMode,
    );

    if (isOfflineMode) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.offlineDownloads),
          centerTitle: false,
        ),
        body: const _OfflineBody(),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: IconTitle(title: context.l10n.downloads),
          centerTitle: false,
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            splashBorderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            tabs: [
              Tab(text: context.l10n.manager),
              Tab(text: context.l10n.movies),
              Tab(text: context.l10n.tvShows),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ManagerTab(),
            _DownloadsGrid(filterType: MediaItemType.movie),
            _DownloadedTvList(),
          ],
        ),
      ),
    );
  }
}

class _ManagerTab extends StatelessWidget {
  const _ManagerTab();

  @override
  Widget build(BuildContext context) {
    final active = context.select<DownloadsBloc, List<DownloadItem>>(
      (b) => b.state.activeDownloads,
    );
    final completed = context.select<DownloadsBloc, List<DownloadItem>>(
      (b) => b.state.completedDownloads,
    );

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
              child: _ActiveDownloadCard(item: item),
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

class _OfflineBody extends StatelessWidget {
  const _OfflineBody();

  @override
  Widget build(BuildContext context) {
    final items = context.select<DownloadsBloc, List<DownloadItem>>(
      (b) => b.state.completedDownloads,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DownloadsGrid extends StatelessWidget {
  const _DownloadsGrid({required this.filterType});
  final MediaItemType filterType;

  @override
  Widget build(BuildContext context) {
    final items = context.select<DownloadsBloc, List<DownloadItem>>(
      (b) => b.state.completedDownloads
          .where((d) => d.type == filterType)
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

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.item});
  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final season = item.parentIndexNumber?.toString().padLeft(2, '0') ?? '??';
    final episode = item.indexNumber?.toString().padLeft(2, '0') ?? '??';

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          unawaited(
            Navigator.of(context).push(OfflineMediaDetailPage.route(item)),
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
                      item.name,
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

class _DownloadPoster extends StatelessWidget {
  const _DownloadPoster({required this.item});
  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: item.name,
      child: GestureDetector(
        onTap: () {
          unawaited(
            Navigator.of(context).push(OfflineMediaDetailPage.route(item)),
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
                  child: item.imageUrl != null
                      ? PlaycadoNetworkImage(
                          imageUrl: item.imageUrl!,
                          width: double.infinity,
                          memCacheWidth: 240,
                          memCacheHeight: 360,
                          placeholder: (context, url) => ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: PlaycadoIcon(
                                PlaycadoIcons.movie,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: PlaycadoIcon(
                              PlaycadoIcons.imageNotFound,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        )
                      : Center(
                          child: PlaycadoIcon(
                            PlaycadoIcons.movie,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                            size: 48,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.productionYear != null
                    ? item.name.replaceAll(' (${item.productionYear})', '')
                    : item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              if (item.productionYear case final year?)
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

class _CompletedDownloadCard extends StatelessWidget {
  const _CompletedDownloadCard({
    required this.item,
    required this.isOfflineMode,
  });
  final DownloadItem item;
  final bool isOfflineMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          unawaited(
            Navigator.of(context).push(OfflineMediaDetailPage.route(item)),
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
                      item.name,
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
                      context.l10n.deletedItem(item.name),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subMessage,
    this.showBrowseButton = true,
  });
  final PlaycadoIcons icon;
  final String message;
  final String subMessage;
  final bool showBrowseButton;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: PlaycadoIcon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (showBrowseButton) ...[
            const SizedBox(height: 32),
            FilledButton.tonalIcon(
              onPressed: () => context.go(AppRouter.basePath),
              icon: const PlaycadoIcon(PlaycadoIcons.home),
              label: Text(context.l10n.browseLibrary),
            ),
          ],
        ],
      ),
    );
  }
}
