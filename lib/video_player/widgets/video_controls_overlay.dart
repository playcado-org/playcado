import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/video_player/bloc/video_player_bloc.dart';
import 'package:playcado/video_player/widgets/track_selection_sheet.dart';
import 'package:playcado/video_player/widgets/video_slider.dart';
import 'package:playcado/widgets/widgets.dart';

class VideoControlsOverlay extends StatefulWidget {
  const VideoControlsOverlay({
    required this.player,
    required this.title,
    super.key,
    this.isFullscreen = false,
    this.onFullscreenToggle,
  });
  final Player player;
  final String title;
  final bool isFullscreen;
  final VoidCallback? onFullscreenToggle;

  @override
  State<VideoControlsOverlay> createState() => _VideoControlsOverlayState();
}

class _VideoControlsOverlayState extends State<VideoControlsOverlay> {
  bool _visible = true;
  Timer? _hideTimer;
  bool _isPlaying = false;
  StreamSubscription<bool>? _playingSubscription;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.player.state.playing;
    if (_isPlaying) _startHideTimer();

    _playingSubscription = widget.player.stream.playing.listen((playing) {
      if (!mounted) return;
      setState(() => _isPlaying = playing);
      if (playing) {
        _startHideTimer();
      } else {
        _cancelHideTimer();
        setState(() => _visible = true);
      }
    });
  }

  @override
  void dispose() {
    _cancelHideTimer();
    unawaited(_playingSubscription?.cancel());
    super.dispose();
  }

  void _startHideTimer() {
    _cancelHideTimer();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() => _visible = false);
      }
    });
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
  }

  void _toggleVisibility() {
    setState(() => _visible = !_visible);
    if (_visible && _isPlaying) _startHideTimer();
  }

  void _onInteraction() {
    if (!_visible) setState(() => _visible = true);
    if (_isPlaying) {
      _startHideTimer();
    } else {
      _cancelHideTimer();
    }
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
        unawaited(
          widget.player.seek(widget.player.state.position + seekAmount),
        );
        _onInteraction();
      },
      child: BlocBuilder<VideoPlayerBloc, VideoPlayerState>(
        builder: (context, state) {
          return Stack(
            children: [
              _AnimatedVisibility(
                visible: _visible,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TopButtons(
                      player: widget.player,
                      onAction: _onInteraction,
                      item: state.mediaItem,
                    ),
                    _CenterControls(
                      player: widget.player,
                      visible: _visible,
                      onAction: _onInteraction,
                    ),
                    _BottomControls(
                      player: widget.player,
                      isFullscreen: widget.isFullscreen,
                      onFullscreenToggle: widget.onFullscreenToggle,
                      onInteractionStart: _cancelHideTimer,
                      onInteractionEnd: () {
                        if (_isPlaying) _startHideTimer();
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
                      context.read<VideoPlayerBloc>().add(
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
  const _CenterControls({
    required this.player,
    required this.visible,
    required this.onAction,
  });
  final Player player;
  final bool visible;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.stream.buffering,
      initialData: player.state.buffering,
      builder: (context, snapshot) {
        final isBuffering = snapshot.data ?? false;

        if (isBuffering) {
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
                unawaited(
                  player.seek(
                    player.state.position - const Duration(seconds: 10),
                  ),
                );
                onAction();
              },
            ),
            const SizedBox(width: 32),
            StreamBuilder<bool>(
              stream: player.stream.playing,
              initialData: player.state.playing,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                return IconButton(
                  color: Colors.white,
                  icon: PlaycadoIcon(
                    isPlaying ? PlaycadoIcons.pause : PlaycadoIcons.play,
                    size: 48,
                  ),
                  onPressed: () {
                    unawaited(player.playOrPause());
                    onAction();
                  },
                );
              },
            ),
            const SizedBox(width: 32),
            IconButton(
              color: Colors.white.withValues(alpha: 0.8),
              icon: const PlaycadoIcon(PlaycadoIcons.forward10, size: 36),
              onPressed: () {
                unawaited(
                  player.seek(
                    player.state.position + const Duration(seconds: 10),
                  ),
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
  const _TopButtons({required this.player, required this.onAction, this.item});
  final Player player;
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
                  builder: (context) => TrackSelectionSheet(player: player),
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
    required this.player,
    required this.isFullscreen,
    required this.onFullscreenToggle,
    required this.onInteractionStart,
    required this.onInteractionEnd,
  });
  final Player player;
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
              player: player,
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
