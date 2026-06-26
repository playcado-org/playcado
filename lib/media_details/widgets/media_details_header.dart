import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/services/media_url/media_url_service.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/player/views/player.dart';
import 'package:playcado/widgets/widgets.dart';

/// Displays the media details header
class MediaDetailsHeader extends StatelessWidget {
  const MediaDetailsHeader({
    required this.item,
    required this.isItemPlaying,
    required this.playerState,
    required this.heroTag,
    super.key,
    this.playingItem,
    this.localBackdropPath,
  });
  final MediaItem item;
  final bool isItemPlaying;
  final MediaItem? playingItem;
  final PlayerState playerState;
  final String heroTag;
  final String? localBackdropPath;

  @override
  Widget build(BuildContext context) {
    final urlGenerator = context.read<MediaUrlService>();
    final backdropUrl = urlGenerator.getItemBackdropUrl(item);

    final videoHeight = MediaQuery.of(context).size.width * (9 / 16);
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: videoHeight,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.black,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          child: BackButton(onPressed: () => context.pop()),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: isItemPlaying && !playerState.isCasting
            ? Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                height: videoHeight,
                child: Player(
                  item: playingItem!,
                  localPath: playerState.localPath,
                ),
              )
            : Hero(
                tag: heroTag,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlaycadoImage(
                      imageUrl: backdropUrl,
                      localFile: localBackdropPath,
                      placeholder: (context, url) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: PlaycadoIcon(
                            PlaycadoIcons.image,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: PlaycadoIcon(
                            PlaycadoIcons.imageNotFound,
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black54,
                            Colors.black,
                          ],
                          stops: [0.0, 0.4, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
