import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:playcado/app_router/app_router.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/downloads/bloc/downloads_bloc.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/media_details/widgets/media_details_actions.dart';
import 'package:playcado/series_details/bloc/series_details_bloc.dart';
import 'package:playcado/series_details/widgets/widgets.dart';
import 'package:playcado/widgets/snackbar_helper.dart';

class SeriesActionRow extends StatelessWidget {
  const SeriesActionRow({
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
        SeriesNextUpButton(
          item: item,
          onPlay: (episode) => onPlay(episode, null),
          isCasting: isCasting,
          isPlaying: isPlaying,
        ),
        const SizedBox(height: 24),
        BlocBuilder<SeriesDetailsBloc, SeriesDetailsState>(
          builder: (context, state) {
            final series = state.series.value ?? item;

            VoidCallback? onDownloadSeason;
            String? downloadSeasonLabel;

            if (series.type == MediaItemType.series &&
                state.expandedSeasonId != null) {
              final season = state.seasons.value?.firstWhere(
                (s) => s.id == state.expandedSeasonId,
                orElse: () => series,
              );
              downloadSeasonLabel = context.l10n.downloadSeason(
                season?.name ?? 'Season',
              );
              onDownloadSeason = () {
                final episodes = state.episodes.value?[state.expandedSeasonId];
                if (episodes != null && episodes.isNotEmpty) {
                  for (final ep in episodes) {
                    context.read<DownloadsBloc>().add(
                      DownloadsRequested(item: ep),
                    );
                  }
                  SnackbarHelper.showInfo(
                    context,
                    context.l10n.downloadingSeason,
                  );
                  context.go(AppRouter.downloadsPath, extra: Object());
                }
              };
            }

            return MediaDetailsActions(
              item: item,
              isWatched: series.isPlayed,
              isLoading: isLoading,
              onToggleWatched: () =>
                  context.read<SeriesDetailsBloc>().add(TogglePlayedStatus()),
              onDownloadSeason: onDownloadSeason,
              downloadSeasonLabel: downloadSeasonLabel,
            );
          },
        ),
      ],
    );
  }
}
