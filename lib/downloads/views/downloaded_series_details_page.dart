import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/core/formatters.dart';
import 'package:playcado/downloads/bloc/downloads_bloc.dart';
import 'package:playcado/downloads/models/downloaded_media_item.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/media_details/widgets/widgets.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/services/media_url/media_url_service.dart';
import 'package:playcado/widgets/widgets.dart';

class DownloadedSeriesDetailsPage extends StatefulWidget {
  const DownloadedSeriesDetailsPage({
    required this.seriesId,
    required this.seriesName,
    super.key,
  });

  final String seriesId;
  final String seriesName;

  @override
  State<DownloadedSeriesDetailsPage> createState() =>
      _DownloadedSeriesDetailsPageState();
}

class _DownloadedSeriesDetailsPageState
    extends State<DownloadedSeriesDetailsPage> {
  late final ScrollController _scrollController;
  String? _expandedSeasonKey;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onPlay(MediaItem item, String? localPath) {
    context.read<PlayerBloc>().add(
      PlayerPlayRequested(item: item, localPath: localPath),
    );
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      unawaited(
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final episodes = context.select<DownloadsBloc, List<DownloadedMediaItem>>(
      (b) =>
          b.state.offlineLibrary
              .where(
                (d) =>
                    d.media.type == MediaItemType.episode &&
                    (d.media.seriesId == widget.seriesId ||
                        d.media.seriesName == widget.seriesName),
              )
              .toList()
            ..sort((a, b) {
              final sa = a.media.parentIndexNumber ?? 0;
              final sb = b.media.parentIndexNumber ?? 0;
              if (sa != sb) return sa.compareTo(sb);
              final ea = a.media.indexNumber ?? 0;
              final eb = b.media.indexNumber ?? 0;
              return ea.compareTo(eb);
            }),
    );

    if (episodes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.seriesName), centerTitle: false),
        body: const Center(child: Text('No episodes found')),
      );
    }

    final seasonMap = <int, List<DownloadedMediaItem>>{};
    final seenSeasons = <int>{};
    for (final ep in episodes) {
      final seasonNum = ep.media.parentIndexNumber ?? 0;
      seasonMap.putIfAbsent(seasonNum, () => []);
      seasonMap[seasonNum]!.add(ep);
      seenSeasons.add(seasonNum);
    }

    final sortedSeasonKeys = seasonMap.keys.toList()..sort();

    _expandedSeasonKey ??= sortedSeasonKeys.first.toString();

    final firstEp = episodes.first.media;
    final seriesItem = MediaItem(
      childCount: seenSeasons.length,
      id: widget.seriesId,
      name: widget.seriesName,
      productionYear: firstEp.productionYear,
      type: MediaItemType.series,
    );

    DownloadedMediaItem? nextUp;
    DownloadedMediaItem? resumeEp;
    for (final ep in episodes) {
      if (resumeEp == null && (ep.media.playbackPositionTicks ?? 0) > 0) {
        resumeEp = ep;
      }
      if (nextUp == null && !ep.media.isPlayed) {
        nextUp = ep;
      }
    }

    final playableItem = resumeEp ?? nextUp ?? episodes.first;

    final allPeople = <String, MediaPerson>{};
    for (final ep in episodes) {
      if (ep.media.people case final people?) {
        for (final person in people) {
          allPeople.putIfAbsent(person.id, () => person);
        }
      }
    }
    final aggregatedPeople = allPeople.values.toList();

    final selectedSeasonKey = int.tryParse(_expandedSeasonKey!);
    final selectedSeasonEpisodes = selectedSeasonKey != null
        ? seasonMap[selectedSeasonKey] ?? <DownloadedMediaItem>[]
        : <DownloadedMediaItem>[];

    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) =>
          prev.mediaItem?.id != curr.mediaItem?.id ||
          prev.status != curr.status ||
          prev.isCasting != curr.isCasting,
      builder: (context, playerState) {
        final isSeriesPlaying = playerState.containsItem(seriesItem);
        final playingItem = playerState.mediaItem;

        final MediaItem effectiveItem;
        if (isSeriesPlaying && playingItem != null) {
          effectiveItem = playingItem;
        } else {
          effectiveItem = playableItem.media;
        }

        final isResuming = (playableItem.media.playbackPositionTicks ?? 0) > 0;

        return MultiBlocListener(
          listeners: [
            BlocListener<PlayerBloc, PlayerState>(
              listenWhen: (previous, current) =>
                  (previous.status != PlayerStatus.loading &&
                      current.status == PlayerStatus.loading) ||
                  (previous.status != PlayerStatus.playing &&
                      current.status == PlayerStatus.playing) ||
                  (previous.mediaItem?.id != current.mediaItem?.id),
              listener: (context, state) {
                if (state.mediaItem != null &&
                    (state.mediaItem!.seriesId == widget.seriesId ||
                        state.mediaItem!.seriesName == widget.seriesName)) {
                  _scrollToTop();
                }
              },
            ),
          ],
          child: Scaffold(
            body: CustomScrollView(
              controller: _scrollController,
              slivers: [
                MediaDetailsHeader(
                  heroTag: 'downloaded_series_${widget.seriesId}',
                  isItemPlaying: isSeriesPlaying,
                  item: effectiveItem,
                  playerState: playerState,
                  playingItem: playingItem,
                  localBackdropPath: playableItem.localBackdropPath,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MediaDetailsTitle(item: seriesItem),
                        const SizedBox(height: 24),
                        LargePlayButton(
                          label: isResuming
                              ? '${context.l10n.resume}: '
                                    'S${playableItem.media.parentIndexNumber} '
                                    'E${playableItem.media.indexNumber}'
                              : '${context.l10n.play}: '
                                    'S${playableItem.media.parentIndexNumber} '
                                    'E${playableItem.media.indexNumber}',
                          onPressed: () => _onPlay(
                            playableItem.media,
                            playableItem.localPath,
                          ),
                        ),
                        const SizedBox(height: 24),
                        MediaDetailsOverview(item: effectiveItem),
                        if (sortedSeasonKeys.length > 1) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                canvasColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  icon: const PlaycadoIcon(
                                    PlaycadoIcons.arrowDown,
                                  ),
                                  onChanged: (newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _expandedSeasonKey = newValue;
                                      });
                                    }
                                  },
                                  items: sortedSeasonKeys.map((num) {
                                    return DropdownMenuItem<String>(
                                      value: num.toString(),
                                      child: Text(
                                        num == 0 ? 'Specials' : 'Season $num',
                                      ),
                                    );
                                  }).toList(),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  value: _expandedSeasonKey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        ...selectedSeasonEpisodes.map(
                          (ep) => _EpisodeTile(
                            episode: ep,
                            onPlay: () => _onPlay(ep.media, ep.localPath),
                          ),
                        ),
                        if (aggregatedPeople.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          MediaDetailsCast(
                            people: aggregatedPeople,
                            localImagePaths: _buildLocalCastImagePaths(
                              episodes,
                              aggregatedPeople,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              for (final ep in episodes) {
                                context.read<DownloadsBloc>().add(
                                  DownloadsDeleteRequested(ep.id),
                                );
                              }
                              SnackbarHelper.showInfo(
                                context,
                                context.l10n.deletedItem(widget.seriesName),
                              );
                              Navigator.of(context).pop();
                            },
                            icon: const PlaycadoIcon(PlaycadoIcons.trash),
                            label: Text(context.l10n.delete),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.error.withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Map<String, String>? _buildLocalCastImagePaths(
  List<DownloadedMediaItem> episodes,
  List<MediaPerson> people,
) {
  final firstPosterPath = episodes.firstOrNull?.localPosterPath;
  if (firstPosterPath == null) return null;

  final dir = Directory(firstPosterPath).parent.path;
  final paths = <String, String>{};
  for (final person in people) {
    final castPath = '$dir/${person.id}_cast.jpg';
    if (File(castPath).existsSync()) {
      paths[person.id] = castPath;
    }
  }
  return paths.isNotEmpty ? paths : null;
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.episode, required this.onPlay});
  final DownloadedMediaItem episode;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imgUrl = context.read<MediaUrlService>().getItemImageUrl(
      episode.media,
      isLandscape: true,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onPlay,
                  child: Builder(
                    builder: (context) {
                      final scale = MediaQuery.textScalerOf(context).scale(1);
                      final thumbWidth = 140.0 * scale;
                      final thumbHeight = 80.0 * scale;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: PlaycadoImage(
                              imageUrl: imgUrl,
                              localFile: episode.localPosterPath,
                              width: thumbWidth,
                              height: thumbHeight,
                              memCacheWidth: 350,
                              placeholder: (context, url) => Container(
                                width: thumbWidth,
                                height: thumbHeight,
                                color: colorScheme.surfaceContainerHighest,
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: thumbWidth,
                                height: thumbHeight,
                                color: colorScheme.surfaceContainerHighest,
                                child: const PlaycadoIcon(PlaycadoIcons.movie),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const PlaycadoIcon(
                              PlaycadoIcons.play,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${episode.media.indexNumber}. ${episode.media.name}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (episode.media.runTimeTicks != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatDuration(
                            episode.media.runTimeTicks!,
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (episode.totalBytes > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatBytes(episode.totalBytes),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (episode.media.overview case final overview?
                when overview.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  overview,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
