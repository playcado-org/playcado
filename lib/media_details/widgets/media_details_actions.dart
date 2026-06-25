import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:playcado/app_router/app_router.dart';
import 'package:playcado/cast/widgets/cast_dialog.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/downloads/bloc/downloads_bloc.dart';
import 'package:playcado/downloads/models/active_download.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/widgets/widgets.dart';

class MediaDetailsActions extends StatelessWidget {
  const MediaDetailsActions({
    required this.item,
    required this.isWatched,
    required this.onToggleWatched,
    super.key,
    this.onDownloadSeason,
    this.downloadSeasonLabel,
    this.isLoading = false,
  });
  final MediaItem item;
  final bool isWatched;
  final VoidCallback onToggleWatched;
  final VoidCallback? onDownloadSeason;
  final String? downloadSeasonLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const _ActionButtonShimmer();
    }

    final isCasting = context.select<PlayerBloc, bool>(
      (b) => b.state.isCasting,
    );

    return BlocBuilder<DownloadsBloc, DownloadsState>(
      builder: (context, downloadsState) {
        final isDownloaded = downloadsState.offlineLibrary.any(
          (d) => d.id == item.id,
        );
        final activeDownload = downloadsState.activeDownloads
            .where((d) => d.id == item.id)
            .fold<ActiveDownload?>(null, (prev, elem) => elem);

        Widget downloadIcon = const PlaycadoIcon(PlaycadoIcons.download);
        var downloadLabel = context.l10n.download;
        Color? downloadIconColor;

        if (isDownloaded) {
          downloadIcon = PlaycadoIcon(
            PlaycadoIcons.check,
            color: theme.colorScheme.primary,
          );
          downloadLabel = context.l10n.downloaded;
          downloadIconColor = theme.colorScheme.primary;
        } else if (activeDownload != null) {
          switch (activeDownload.status) {
            case ActiveDownloadStatus.queued:
              downloadIcon = PlaycadoIcon(
                PlaycadoIcons.clock,
                color: theme.colorScheme.primary,
              );
              downloadLabel = context.l10n.queued;
            case ActiveDownloadStatus.downloading:
              downloadIcon = PlaycadoIcon(
                PlaycadoIcons.download,
                color: theme.colorScheme.primary,
              );
              downloadLabel = '${(activeDownload.progress * 100).toInt()}%';
              downloadIconColor = theme.colorScheme.primary;
            case ActiveDownloadStatus.paused:
              downloadIcon = const PlaycadoIcon(PlaycadoIcons.pauseCircle);
              downloadLabel = context.l10n.paused;
            case ActiveDownloadStatus.error:
              downloadIcon = const PlaycadoIcon(PlaycadoIcons.alert);
              downloadLabel = context.l10n.failed;
              downloadIconColor = theme.colorScheme.error;
          }
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ActionButton(
                icon: PlaycadoIcon(
                  isWatched ? PlaycadoIcons.view : PlaycadoIcons.viewOff,
                  color: isWatched ? theme.colorScheme.primary : null,
                ),
                label: isWatched
                    ? context.l10n.watched
                    : context.l10n.unwatched,
                onTap: onToggleWatched,
              ),
            ),
            if (onDownloadSeason != null)
              Expanded(
                child: _ActionButton(
                  icon: const PlaycadoIcon(PlaycadoIcons.check),
                  label: downloadSeasonLabel ?? 'Season',
                  onTap: onDownloadSeason!,
                ),
              ),
            if (item.type == MediaItemType.movie ||
                item.type == MediaItemType.video ||
                item.type == MediaItemType.episode)
              Expanded(
                child: _ActionButton(
                  icon: downloadIcon,
                  iconColor: downloadIconColor,
                  label: item.type == MediaItemType.episode
                      ? '${context.l10n.download} '
                            'S${item.parentIndexNumber} '
                            'E${item.indexNumber}'
                      : downloadLabel,
                    onTap: () {
                    if (isDownloaded) {
                      final downloadedItem = downloadsState.offlineLibrary
                          .firstWhere((d) => d.id == item.id);
                      context.push(
                        AppRouter.offlineMediaDetailPath,
                        extra: downloadedItem,
                      );
                    } else if (activeDownload == null ||
                        activeDownload.status == ActiveDownloadStatus.error) {
                      context.read<DownloadsBloc>().add(
                        DownloadsRequested(item: item),
                      );
                      if (item.type == MediaItemType.episode) {
                        SnackbarHelper.showInfo(
                          context,
                          context.l10n.downloadingEpisode,
                        );
                      }
                      context.go(AppRouter.downloadsPath);
                    }
                  },
                ),
              ),
            Expanded(
              child: _ActionButton(
                icon: const PlaycadoIcon(PlaycadoIcons.cast),
                iconColor: isCasting ? theme.colorScheme.primary : null,
                label: isCasting
                    ? context.l10n.castingToDevice
                    : context.l10n.cast,
                onTap: () {
                  unawaited(
                    showDialog<void>(
                      context: context,
                      builder: (context) =>
                          CastDeviceListDialog(autoPlayItem: item),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });
  final Widget icon;
  final Color? iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: iconColor ?? theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtonShimmer extends StatelessWidget {
  const _ActionButtonShimmer();

  @override
  Widget build(BuildContext context) {
    return PlaycadoShimmer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          4,
          (index) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 45,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
