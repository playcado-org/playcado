import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/media_details/widgets/media_details_actions.dart';
import 'package:playcado/movie_details/bloc/movie_details_bloc.dart';
import 'package:playcado/movie_details/widgets/widgets.dart';

class MovieActionRow extends StatelessWidget {
  const MovieActionRow({
    required this.item,
    required this.onPlay,
    super.key,
    this.isLoading = false,
    this.isCasting = false,
    this.isPlaying = false,
  });
  final MediaItem item;
  final void Function(MediaItem item, String? localPath) onPlay;
  final bool isLoading;
  final bool isCasting;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MoviePlayButton(
          item: item,
          onPlay: (path) => onPlay(item, path),
          isLoading: isLoading,
          isCasting: isCasting,
          isPlaying: isPlaying,
        ),
        const SizedBox(height: 24),
        BlocBuilder<MovieDetailsBloc, MovieDetailsState>(
          builder: (context, state) {
            final movie = state.movie.value ?? item;
            return MediaDetailsActions(
              item: item,
              isWatched: movie.isPlayed,
              isLoading: isLoading,
              onToggleWatched: () => context.read<MovieDetailsBloc>().add(
                const ToggleMoviePlayedStatus(),
              ),
            );
          },
        ),
      ],
    );
  }
}
