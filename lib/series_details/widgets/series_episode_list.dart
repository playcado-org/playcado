import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/core/formatters.dart';
import 'package:playcado/downloads/widgets/media_download_button.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/series_details/bloc/series_details_bloc.dart';
import 'package:playcado/services/media_url/media_url_service.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/widgets/widgets.dart';

class SeriesEpisodeList extends StatelessWidget {
  const SeriesEpisodeList({
    required this.seriesId,
    required this.onPlay,
    super.key,
  });
  final String seriesId;
  final void Function(MediaItem item) onPlay;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SeriesDetailsBloc, SeriesDetailsState>(
      builder: (context, state) {
        if (state.seasons.isLoading) {
          return const _SeriesEpisodeListSkeleton();
        } else if (state.seasons.isError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(context.l10n.errorLoadingSeasons),
          );
        }

        final seasons = state.seasons.value ?? [];
        if (seasons.isEmpty) {
          return const SizedBox.shrink();
        }

        final selectedSeasonId = state.expandedSeasonId ?? seasons.first.id;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    value: selectedSeasonId,
                    icon: const PlaycadoIcon(PlaycadoIcons.arrowDown),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (newValue) {
                      if (newValue != null &&
                          newValue != state.expandedSeasonId) {
                        context.read<SeriesDetailsBloc>().add(
                          FetchEpisodes(seriesId: seriesId, seasonId: newValue),
                        );
                      }
                    },
                    items: seasons.map<DropdownMenuItem<String>>((season) {
                      return DropdownMenuItem<String>(
                        value: season.id,
                        child: Text(season.name),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _EpisodeList(seasonId: selectedSeasonId, onPlay: onPlay),
          ],
        );
      },
    );
  }
}

class _EpisodeList extends StatelessWidget {
  const _EpisodeList({required this.seasonId, required this.onPlay});
  final String seasonId;
  final void Function(MediaItem item) onPlay;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SeriesDetailsBloc, SeriesDetailsState>(
      builder: (context, state) {
        final episodes = state.episodes.value?[seasonId] ?? [];

        if (state.episodes.isLoading && episodes.isEmpty) {
          return const PlaycadoShimmer(
            child: Column(
              children: [
                _EpisodeSkeletonTile(),
                _EpisodeSkeletonTile(),
                _EpisodeSkeletonTile(),
              ],
            ),
          );
        }

        if (episodes.isEmpty && !state.episodes.isLoading) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(context.l10n.noEpisodesFound),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: episodes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            final episode = episodes[index];
            return _EpisodeTile(episode: episode, onPlay: onPlay);
          },
        );
      },
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.episode, required this.onPlay});
  final MediaItem episode;
  final void Function(MediaItem item) onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imgUrl = context.read<MediaUrlService>().getItemImageUrl(
      episode,
      isLandscape: true,
    );

    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) =>
          (prev.mediaItem?.id == episode.id) !=
              (curr.mediaItem?.id == episode.id) ||
          prev.isActive != curr.isActive,
      builder: (context, playerState) {
        final isPlaying =
            playerState.mediaItem?.id == episode.id && playerState.isActive;

        return Semantics(
          label: '${episode.indexNumber}. ${episode.name}',
          child: InkWell(
            onTap: () {
              context.read<SeriesDetailsBloc>().add(
                SelectEpisode(episode: episode),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Semantics(
                      button: true,
                      label: '${context.l10n.play} ${episode.name}',
                      child: GestureDetector(
                        onTap: () {
                          context.read<SeriesDetailsBloc>().add(
                            SelectEpisode(episode: episode),
                          );
                          onPlay(episode);
                        },
                        child: Builder(
                          builder: (context) {
                            final scale = MediaQuery.textScalerOf(
                              context,
                            ).scale(1);
                            final thumbWidth = 140.0 * scale;
                            final thumbHeight = 80.0 * scale;
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: PlaycadoNetworkImage(
                                    imageUrl: imgUrl,
                                    width: thumbWidth,
                                    height: thumbHeight,
                                    memCacheWidth: 350,
                                    placeholder: (context, url) => Container(
                                      width: thumbWidth,
                                      height: thumbHeight,
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          width: thumbWidth,
                                          height: thumbHeight,
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                          child: const PlaycadoIcon(
                                            PlaycadoIcons.movie,
                                          ),
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
                                  child: PlaycadoIcon(
                                    isPlaying
                                        ? PlaycadoIcons.graphicEq
                                        : PlaycadoIcons.play,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${episode.indexNumber}. ${episode.name}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isPlaying ? colorScheme.primary : null,
                            ),
                          ),
                          if (episode.runTimeTicks != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatDuration(episode.runTimeTicks),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    MediaDownloadButton(item: episode),
                  ],
                ),
                if (episode.overview case final overview?
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
      },
    );
  }
}

class _SeriesEpisodeListSkeleton extends StatelessWidget {
  const _SeriesEpisodeListSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PlaycadoShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          const _EpisodeSkeletonTile(),
          const _EpisodeSkeletonTile(),
          const _EpisodeSkeletonTile(),
        ],
      ),
    );
  }
}

class _EpisodeSkeletonTile extends StatelessWidget {
  const _EpisodeSkeletonTile();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 140,
                height: 80,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 200,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
