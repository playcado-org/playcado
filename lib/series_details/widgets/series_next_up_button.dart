import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/core/formatters.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/media_details/widgets/widgets.dart';
import 'package:playcado/series_details/bloc/series_details_bloc.dart';
import 'package:playcado/widgets/widgets.dart';

class SeriesNextUpButton extends StatelessWidget {
  const SeriesNextUpButton({
    required this.item,
    required this.onPlay,
    super.key,
    this.isCasting = false,
    this.isPlaying = false,
  });
  final MediaItem item;
  final void Function(MediaItem item) onPlay;
  final bool isCasting;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    if (isPlaying) {
      return ActivePlaybackControls(isCasting: isCasting);
    }

    return BlocBuilder<SeriesDetailsBloc, SeriesDetailsState>(
      builder: (context, state) {
        if (state.nextEpisode.isLoading) {
          return const _SeriesNextUpButtonShimmer();
        }

        final playableItem = (item.type == MediaItemType.episode)
            ? item
            : state.nextEpisode.value;

        if (playableItem == null) {
          return const SizedBox.shrink();
        }

        final resumeTicks = playableItem.playbackPositionTicks ?? 0;
        final isResuming = resumeTicks > 0;

        String prefix;
        if (isCasting) {
          prefix = context.l10n.castingToDevice;
        } else if (isResuming) {
          prefix = context.l10n.resume;
        } else if (item.type == MediaItemType.series) {
          prefix = context.l10n.next;
        } else {
          prefix = context.l10n.play;
        }

        String labelText;
        if (isCasting) {
          labelText = prefix;
        } else {
          labelText =
              '$prefix: '
              'S${playableItem.parentIndexNumber} '
              'E${playableItem.indexNumber}';
          if (isResuming) {
            final remaining = Formatters.formatTimeRemaining(
              (playableItem.runTimeTicks ?? 0) - resumeTicks,
            );
            if (remaining.isNotEmpty) {
              labelText = '$labelText • $remaining';
            }
          }
        }

        return LargePlayButton(
          label: labelText,
          onPressed: () => onPlay(playableItem),
        );
      },
    );
  }
}

class _SeriesNextUpButtonShimmer extends StatelessWidget {
  const _SeriesNextUpButtonShimmer();

  @override
  Widget build(BuildContext context) {
    return PlaycadoShimmer(
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: const ShapeDecoration(
          color: Colors.white,
          shape: StadiumBorder(),
        ),
      ),
    );
  }
}
