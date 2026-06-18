import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/core/formatters.dart';
import 'package:playcado/downloads/bloc/downloads_bloc.dart';
import 'package:playcado/downloads/models/download_item.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/media_details/widgets/widgets.dart';
import 'package:playcado/widgets/widgets.dart';

/// A large play button used in media details.
class MoviePlayButton extends StatelessWidget {
  const MoviePlayButton({
    required this.item,
    required this.onPlay,
    super.key,
    this.isCasting = false,
    this.isPlaying = false,
    this.isLoading = false,
  });
  final MediaItem item;
  final void Function(String? localPath) onPlay;
  final bool isCasting;
  final bool isPlaying;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _MoviePlayButtonShimmer();
    }

    if (isPlaying) {
      return ActivePlaybackControls(isCasting: isCasting);
    }

    return BlocBuilder<DownloadsBloc, DownloadsState>(
      builder: (context, state) {
        final downloadItem = state.downloads
            .where((d) => d.id == item.id)
            .fold<DownloadItem?>(null, (prev, elem) => elem);

        final isDownloaded = downloadItem?.status == DownloadStatus.completed;

        String labelText;
        final ticks = item.playbackPositionTicks ?? 0;
        final isResuming = ticks > 0;

        if (isCasting) {
          labelText = context.l10n.castingToDevice;
        } else if (isDownloaded) {
          labelText = isResuming
              ? context.l10n.resume
              : context.l10n.playOffline;
        } else {
          labelText = isResuming ? context.l10n.resume : context.l10n.play;
        }

        if (isResuming && !isCasting) {
          final remaining = Formatters.formatTimeRemaining(
            (item.runTimeTicks ?? 0) - ticks,
          );
          if (remaining.isNotEmpty) {
            labelText = '$labelText • $remaining';
          }
        }

        return LargePlayButton(
          label: labelText,
          onPressed: () =>
              onPlay(isDownloaded ? downloadItem?.localPath : null),
        );
      },
    );
  }
}

class _MoviePlayButtonShimmer extends StatelessWidget {
  const _MoviePlayButtonShimmer();

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
