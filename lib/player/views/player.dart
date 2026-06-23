import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:playcado/app_router/app_router.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/player/services/player_service.dart';
import 'package:playcado/player/widgets/video_controls_overlay.dart';

class Player extends StatefulWidget {
  const Player({
    required this.item,
    super.key,
    this.localPath,
    this.isFullscreen = false,
  });
  final MediaItem item;
  final String? localPath;
  final bool isFullscreen;

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  Future<void> _handleFullscreenToggle() async {
    if (widget.isFullscreen) {
      if (context.canPop()) {
        context.pop();
      }
    } else {
      await context.push(AppRouter.videoPlayerPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) =>
          prev.playerView?.runtimeType != curr.playerView?.runtimeType ||
          prev.mediaItem?.id != curr.mediaItem?.id,
      builder: (context, state) {
        final title = state.mediaItem?.name ?? widget.item.name;
        final playerView = state.playerView;

        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Hero(
                  tag: 'video_player_${widget.item.id}',
                  child: switch (playerView) {
                    LocalPlayerView(:final controller) => Video(
                      controller: controller as VideoController,
                      controls: NoVideoControls as VideoControlsBuilder?,
                    ),
                    CastPlayerView() => const SizedBox.shrink(),
                    null => const SizedBox.shrink(),
                  },
                ),
              ),
              VideoControlsOverlay(
                title: title,
                isFullscreen: widget.isFullscreen,
                onFullscreenToggle: _handleFullscreenToggle,
              ),
            ],
          ),
        );
      },
    );
  }
}
