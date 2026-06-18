import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:playcado/app_router/app_router.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/video_player/bloc/video_player_bloc.dart';
import 'package:playcado/video_player/widgets/video_controls_overlay.dart';

class VideoPlayer extends StatefulWidget {
  const VideoPlayer({
    required this.item,
    super.key,
    this.localPath,
    this.isFullscreen = false,
  });
  final MediaItem item;
  final String? localPath;
  final bool isFullscreen;

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
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
    return BlocBuilder<VideoPlayerBloc, VideoPlayerState>(
      builder: (context, state) {
        final title = state.mediaItem?.name ?? widget.item.name;
        final attachment = state.nativeViewAttachment;

        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Hero(
                  tag: 'video_player_${widget.item.id}',
                  child: attachment is VideoController
                      ? Video(
                          controller: attachment,
                          controls: NoVideoControls as VideoControlsBuilder?,
                        )
                      : const SizedBox.shrink(),
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
