import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/core/formatters.dart';
import 'package:playcado/downloads/bloc/downloads_bloc.dart';
import 'package:playcado/downloads/models/downloaded_media_item.dart';
import 'package:playcado/media_details/widgets/widgets.dart';
import 'package:playcado/movie_details/widgets/widgets.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/widgets/widgets.dart';

class OfflineMediaDetailPage extends StatelessWidget {
  const OfflineMediaDetailPage({required this.item, super.key});
  final DownloadedMediaItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final mediaItem = item.media;
    final heroTag = 'offline_${mediaItem.id}';

    return Scaffold(
      body: BlocBuilder<PlayerBloc, PlayerState>(
        buildWhen: (prev, curr) =>
            prev.mediaItem?.id != curr.mediaItem?.id ||
            prev.status != curr.status ||
            prev.isCasting != curr.isCasting,
        builder: (context, playerState) {
          final isItemPlaying = playerState.containsItem(mediaItem);
          final playingItem = playerState.mediaItem;

          return CustomScrollView(
            slivers: [
              MediaDetailsHeader(
                item: mediaItem,
                isItemPlaying: isItemPlaying,
                playingItem: playingItem,
                playerState: playerState,
                heroTag: heroTag,
                localBackdropPath: item.localBackdropPath,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MediaDetailsTitle(item: mediaItem),
                      if (item.totalBytes > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            Formatters.formatBytes(item.totalBytes),
                            style: TextStyle(
                              color: colorScheme.onSecondaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      MoviePlayButton(
                        item: mediaItem,
                        onPlay: (path) {
                          context.read<PlayerBloc>().add(
                            PlayerPlayRequested(
                              item: mediaItem,
                              localPath: path,
                            ),
                          );
                        },
                        isCasting: playerState.isCasting && isItemPlaying,
                        isPlaying: playerState.isActive && isItemPlaying,
                      ),
                      const SizedBox(height: 24),
                      MediaDetailsOverview(item: mediaItem),
                      if (mediaItem.people case final people?
                          when people.isNotEmpty)
                        MediaDetailsCast(people: people),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<DownloadsBloc>().add(
                              DownloadsDeleteRequested(item.id),
                            );
                            SnackbarHelper.showInfo(
                              context,
                              context.l10n.deletedItem(item.media.name),
                            );
                            Navigator.of(context).pop();
                          },
                          icon: const PlaycadoIcon(PlaycadoIcons.trash),
                          label: Text(context.l10n.delete),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            side: BorderSide(
                              color: colorScheme.error.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
