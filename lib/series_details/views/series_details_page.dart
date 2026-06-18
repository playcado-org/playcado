import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/media/repos/library_repository.dart';
import 'package:playcado/playback/repos/playback_tracker.dart';
import 'package:playcado/media_details/widgets/widgets.dart';
import 'package:playcado/series_details/bloc/series_details_bloc.dart';
import 'package:playcado/series_details/widgets/series_action_row.dart';
import 'package:playcado/series_details/widgets/series_episode_list.dart';
import 'package:playcado/video_player/bloc/video_player_bloc.dart';

class SeriesDetailsPage extends StatefulWidget {
  const SeriesDetailsPage({
    required this.item,
    required this.heroTag,
    super.key,
  });
  final MediaItem item;
  final String heroTag;

  @override
  State<SeriesDetailsPage> createState() => _SeriesDetailsPageState();
}

class _SeriesDetailsPageState extends State<SeriesDetailsPage> {
  late final SeriesDetailsBloc _detailsBloc;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _detailsBloc = SeriesDetailsBloc(
      libraryRepository: context.read<LibraryRepository>(),
      playbackTracker: context.read<PlaybackTracker>(),
    );

    _detailsBloc.add(SeriesDetailsStarted(item: widget.item));
  }

  @override
  void dispose() {
    unawaited(_detailsBloc.close());
    _scrollController.dispose();
    super.dispose();
  }

  void _onPlay(BuildContext context, MediaItem item, String? localPath) {
    context.read<VideoPlayerBloc>().add(
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
    return BlocProvider.value(
      value: _detailsBloc,
      child: BlocBuilder<VideoPlayerBloc, VideoPlayerState>(
        builder: (context, playerState) {
          return BlocBuilder<SeriesDetailsBloc, SeriesDetailsState>(
            builder: (context, detailsState) {
              final seriesItem = detailsState.series.value ?? widget.item;
              final isItemPlaying = playerState.containsItem(seriesItem);
              final playingItem = playerState.mediaItem;
              final nextEpisode = detailsState.nextEpisode.value;
              final selectedEpisode = detailsState.selectedEpisode;

              final MediaItem effectiveItem;
              if (selectedEpisode != null) {
                effectiveItem = selectedEpisode;
              } else if (isItemPlaying && playingItem != null) {
                effectiveItem = playingItem;
              } else if (seriesItem.type == MediaItemType.series &&
                  nextEpisode != null) {
                effectiveItem = nextEpisode;
              } else {
                effectiveItem = seriesItem;
              }

              return MultiBlocListener(
                listeners: [
                  BlocListener<VideoPlayerBloc, VideoPlayerState>(
                    listenWhen: (previous, current) {
                      final startedLoading =
                          previous.status != VideoPlayerStatus.loading &&
                          current.status == VideoPlayerStatus.loading;
                      final startedPlaying =
                          previous.status != VideoPlayerStatus.loading &&
                          previous.status != VideoPlayerStatus.playing &&
                          current.status == VideoPlayerStatus.playing;
                      final itemChanged =
                          previous.mediaItem?.id != current.mediaItem?.id;

                      return (startedLoading ||
                              startedPlaying ||
                              itemChanged) &&
                          current.mediaItem != null &&
                          current.containsItem(seriesItem);
                    },
                    listener: (context, state) {
                      _scrollToTop();
                    },
                  ),
                  BlocListener<VideoPlayerBloc, VideoPlayerState>(
                    listenWhen: (prev, curr) =>
                        prev.status != VideoPlayerStatus.stopped &&
                        curr.status == VideoPlayerStatus.stopped,
                    listener: (context, state) {
                      final lastItem = state.mediaItem;
                      if (lastItem != null) {
                        context.read<SeriesDetailsBloc>().add(
                          UpdateLocalPlaybackProgress(
                            itemId: lastItem.id,
                            positionTicks: state.position.inMicroseconds * 10,
                          ),
                        );
                      }
                    },
                  ),
                  BlocListener<SeriesDetailsBloc, SeriesDetailsState>(
                    listenWhen: (previous, current) =>
                        previous.selectedEpisode?.id !=
                        current.selectedEpisode?.id,
                    listener: (context, state) {
                      _scrollToTop();
                    },
                  ),
                ],
                child: Scaffold(
                  body: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      MediaDetailsHeader(
                        item: effectiveItem,
                        isItemPlaying: isItemPlaying,
                        playingItem: playingItem,
                        playerState: playerState,
                        heroTag: widget.heroTag,
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MediaDetailsTitle(item: seriesItem),
                              const SizedBox(height: 24),
                              SeriesActionRow(
                                item: effectiveItem,
                                onPlay: (item, path) =>
                                    _onPlay(context, item, path),
                                isLoading: detailsState.series.isLoading,
                                isCasting:
                                    playerState.isCasting && isItemPlaying,
                                isPlaying:
                                    playerState.isActive && isItemPlaying,
                              ),
                              const SizedBox(height: 24),
                              MediaDetailsOverview(
                                item: effectiveItem,
                                nextEpisode: nextEpisode,
                                isLoading:
                                    detailsState.isNextEpisodeLoading ||
                                    detailsState.isSelectedEpisodeLoading,
                              ),
                              SeriesEpisodeList(
                                seriesId: seriesItem.id,
                                onPlay: (episode) =>
                                    _onPlay(context, episode, null),
                              ),
                              if (effectiveItem.people case final people?
                                  when people.isNotEmpty)
                                MediaDetailsCast(people: people),
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
        },
      ),
    );
  }
}
