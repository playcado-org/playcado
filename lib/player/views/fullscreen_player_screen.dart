import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/player/services/player_service.dart';
import 'package:playcado/player/widgets/cast_control_view.dart';
import 'package:playcado/player/widgets/video_controls_overlay.dart';
import 'package:playcado/widgets/loading_indicator.dart';

class FullscreenPlayerScreen extends StatefulWidget {
  const FullscreenPlayerScreen({super.key});

  @override
  State<FullscreenPlayerScreen> createState() => _FullscreenPlayerScreenState();
}

class _FullscreenPlayerScreenState extends State<FullscreenPlayerScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          if (state.isCasting) {
            return CastControlView(item: state.mediaItem);
          }

          switch (state.playerView) {
            case LocalPlayerView(:final controller):
              return Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Video(
                      controller: controller as VideoController,
                      controls: NoVideoControls as VideoControlsBuilder?,
                    ),
                  ),
                  VideoControlsOverlay(
                    title: state.mediaItem?.name ?? '',
                    isFullscreen: true,
                    onFullscreenToggle: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            case CastPlayerView():
              return CastControlView(item: state.mediaItem);
            case null:
              return const LoadingIndicator();
          }
        },
      ),
    );
  }
}
