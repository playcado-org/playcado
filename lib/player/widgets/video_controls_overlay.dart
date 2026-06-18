import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/player/services/local_player_service.dart';
import 'package:playcado/player/widgets/track_selection_sheet.dart';
import 'package:playcado/player/widgets/video_slider.dart';
import 'package:playcado/widgets/widgets.dart';

class VideoControlsOverlay extends StatefulWidget {
  const VideoControlsOverlay({
    required this.title,
    super.key,
    this.isFullscreen = false,
    this.onFullscreenToggle,
  });
  final String title;
  final bool isFullscreen;
  final VoidCallback? onFullscreenToggle;

  @override
  State<VideoControlsOverlay> createState() => _VideoControlsOverlayState();
}

class _VideoControlsOverlayState extends State<VideoControlsOverlay> {
  bool _visible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _cancelHideTimer();
    super.dispose();
  }

  void _startHideTimer() {
    _cancelHideTimer();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        final isPlaying =
            context.read<PlayerBloc>().state.status ==
            PlayerStatus.playing;
        if (isPlaying) {
          setState(() => _visible = false);
        }
      }
    });
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
  }

  void _toggleVisibility() {
    setState(() => _visible = !_visible);
    if (_visible) _startHideTimer();
  }

  void _onInteraction() {
    if (!_visible) setState(() => _visible = true);
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleVisibility,
      behavior: HitTestBehavior.opaque,
      onDoubleTapDown: (details) {
        final width = MediaQuery.of(context).size.width;
        final isLeft = details.globalPosition.dx < width / 2;
        final seekAmount = isLeft
            ? const Duration(seconds: -10)
            : const Duration(seconds: 10);
        final currentPos = context.read<PlayerBloc>().state.position;
        context.read<PlayerBloc>().add(
          PlayerSeekRequested(currentPos + seekAmount),
        );
        _onInteraction();
      },
      child: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          return Stack(
            children: [
              _AnimatedVisibility(
                visible: _visible,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TopButtons(
                      onAction: _onInteraction,
                      item: state.mediaItem,
                    ),
                    _CenterControls(
                      visible: _visible,
                      onAction: _onInteraction,
                    ),
                    _BottomControls(
                      isFullscreen: widget.isFullscreen,
                      onFullscreenToggle: widget.onFullscreenToggle,
                      onInteractionStart: _cancelHideTimer,
                      onInteractionEnd: () {
                        _startHideTimer();
                      },
                    ),
                  ],
                ),
              ),
              if (state.showSkipIntro)
                Positioned(
                  bottom: widget.isFullscreen ? 100 : 80,
                  right: 24,
                  child: FilledButton.icon(
                    onPressed: () {
                      context.read<PlayerBloc>().add(
                        PlayerSkipIntroRequested(),
                      );
                    },
                    icon: const PlaycadoIcon(PlaycadoIcons.skipNext, size: 20),
                    label: Text(context.l10n.skipIntro),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CenterControls extends StatelessWidget {
  const _CenterControls({required this.visible, required this.onAction});
  final bool visible;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (prev, curr) =>
          prev.isBuffering != curr.isBuffering || prev.status != curr.status,
      builder: (context, state) {
        if (state.isBuffering) {
          return const LoadingIndicator(color: Colors.white);
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              iconSize: 48,
              color: Colors.white.withValues(alpha: 0.8),
              icon: const PlaycadoIcon(PlaycadoIcons.replay10, size: 36),
              onPressed: () {
                final pos = context.read<PlayerBloc>().state.position;
                context.read<PlayerBloc>().add(
                  PlayerSeekRequested(pos - const Duration(seconds: 10)),
                );
                onAction();
              },
            ),
            const SizedBox(width: 32),
            IconButton(
              color: Colors.white,
              icon: PlaycadoIcon(
                state.status == PlayerStatus.playing
                    ? PlaycadoIcons.pause
                    : PlaycadoIcons.play,
                size: 48,
              ),
              onPressed: () {
                context.read<PlayerBloc>().add(
                  PlayerTogglePlayPauseRequested(),
                );
                onAction();
              },
            ),
            const SizedBox(width: 32),
            IconButton(
              color: Colors.white.withValues(alpha: 0.8),
              icon: const PlaycadoIcon(PlaycadoIcons.forward10, size: 36),
              onPressed: () {
                final pos = context.read<PlayerBloc>().state.position;
                context.read<PlayerBloc>().add(
                  PlayerSeekRequested(pos + const Duration(seconds: 10)),
                );
                onAction();
              },
            ),
          ],
        );
      },
    );
  }
}

class _TopButtons extends StatelessWidget {
  const _TopButtons({required this.onAction, this.item});
  final VoidCallback onAction;
  final MediaItem? item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, left: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const PlaycadoIcon(
              PlaycadoIcons.subtitles,
              color: Colors.white,
              size: 28,
            ),
            tooltip: context.l10n.audioAndSubtitles,
            onPressed: () {
              onAction();
              unawaited(
                showModalBottomSheet<void>(
                  context: context,
                  useRootNavigator: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  showDragHandle: true,
                  builder: (context) => TrackSelectionSheet(
                    service: context.read<LocalPlayerService>(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.isFullscreen,
    required this.onFullscreenToggle,
    required this.onInteractionStart,
    required this.onInteractionEnd,
  });
  final bool isFullscreen;
  final VoidCallback? onFullscreenToggle;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: VideoSlider(
              onInteractionStart: onInteractionStart,
              onInteractionEnd: onInteractionEnd,
            ),
          ),
          if (onFullscreenToggle != null) ...[
            const SizedBox(width: 12),
            IconButton(
              icon: PlaycadoIcon(
                isFullscreen
                    ? PlaycadoIcons.fullscreenExit
                    : PlaycadoIcons.fullscreen,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                onInteractionStart();
                onFullscreenToggle!();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimatedVisibility extends StatelessWidget {
  const _AnimatedVisibility({required this.visible, required this.child});
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: IgnorePointer(ignoring: !visible, child: child),
    );
  }
}
