import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/media/repositories/library_repository.dart';
import 'package:playcado/player/repositories/player_tracker_repository.dart';
import 'package:playcado/media_details/widgets/widgets.dart';
import 'package:playcado/movie_details/bloc/movie_details_bloc.dart';
import 'package:playcado/movie_details/widgets/movie_action_row.dart';
import 'package:playcado/player/bloc/player_bloc.dart';

class MovieDetailsPage extends StatefulWidget {
  const MovieDetailsPage({
    required this.item,
    required this.heroTag,
    super.key,
  });
  final MediaItem item;
  final String heroTag;

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  late final MovieDetailsBloc _detailsBloc;
  late ScrollController _scrollController;

  void _onPlay(BuildContext context, MediaItem item, String? localPath) {
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
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _detailsBloc = MovieDetailsBloc(
      libraryRepository: context.read<LibraryRepository>(),
      playbackTracker: context.read<PlayerTrackerRepository>(),
    )..add(FetchMovieDetails(widget.item.id));
  }

  @override
  void dispose() {
    unawaited(_detailsBloc.close());
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _detailsBloc,
      child: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, playerState) {
          return BlocBuilder<MovieDetailsBloc, MovieDetailsState>(
            builder: (context, detailsState) {
              final movieItem = detailsState.movie.value ?? widget.item;
              final isItemPlaying = playerState.containsItem(movieItem);
              final playingItem = playerState.mediaItem;

              final MediaItem effectiveItem;
              if (isItemPlaying && playingItem != null) {
                effectiveItem = playingItem;
              } else {
                effectiveItem = movieItem;
              }

              return MultiBlocListener(
                listeners: [
                  BlocListener<PlayerBloc, PlayerState>(
                    listenWhen: (previous, current) {
                      final startedLoading =
                          previous.status != PlayerStatus.loading &&
                          current.status == PlayerStatus.loading;
                      final startedPlaying =
                          previous.status != PlayerStatus.loading &&
                          previous.status != PlayerStatus.playing &&
                          current.status == PlayerStatus.playing;
                      final itemChanged =
                          previous.mediaItem?.id != current.mediaItem?.id;

                      return (startedLoading ||
                              startedPlaying ||
                              itemChanged) &&
                          current.mediaItem != null &&
                          current.containsItem(movieItem);
                    },
                    listener: (context, state) {
                      _scrollToTop();
                    },
                  ),
                  BlocListener<PlayerBloc, PlayerState>(
                    listenWhen: (prev, curr) =>
                        prev.status != PlayerStatus.stopped &&
                        curr.status == PlayerStatus.stopped,
                    listener: (context, state) {
                      final lastItem = state.mediaItem;
                      if (lastItem != null && lastItem.id == movieItem.id) {
                        context.read<MovieDetailsBloc>().add(
                          UpdateMoviePlaybackProgress(
                            state.position.inMicroseconds * 10,
                          ),
                        );
                      }
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
                              MediaDetailsTitle(item: movieItem),
                              const SizedBox(height: 24),
                              MovieActionRow(
                                item: effectiveItem,
                                onPlay: (item, path) =>
                                    _onPlay(context, item, path),
                                isLoading: detailsState.movie.isLoading,
                                isCasting:
                                    playerState.isCasting && isItemPlaying,
                                isPlaying:
                                    playerState.isActive && isItemPlaying,
                              ),
                              const SizedBox(height: 24),
                              MediaDetailsOverview(
                                item: effectiveItem,
                                isLoading: detailsState.movie.isLoading,
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
