import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:playcado/app_router/app_router.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/widgets/playcado_icon.dart';

/// A row of buttons (Play/Pause, Stop, Fullscreen) shown when media is playing.
class ActivePlaybackControls extends StatelessWidget {
  const ActivePlaybackControls({super.key, this.isCasting = false});
  final bool isCasting;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, playerState) {
        final isPaused = playerState.status != PlayerStatus.playing;

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: _MediaActionButton(
                icon: isPaused ? PlaycadoIcons.play : PlaycadoIcons.pause,
                label: isPaused ? context.l10n.resume : context.l10n.pause,
                isPrimary: true,
                fontSize: 13,
                onPressed: () {
                  if (isPaused) {
                    context.read<PlayerBloc>().add(
                      PlayerResumeRequested(),
                    );
                  } else {
                    context.read<PlayerBloc>().add(PlayerPauseRequested());
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _MediaActionButton(
                icon: PlaycadoIcons.stop,
                label: context.l10n.stop,
                isPrimary: false,
                fontSize: 13,
                onPressed: () {
                  context.read<PlayerBloc>().add(PlayerStopRequested());
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _MediaActionButton(
                icon: PlaycadoIcons.fullscreen,
                label: context.l10n.full,
                isPrimary: false,
                fontSize: 13,
                onPressed: () {
                  unawaited(context.push(AppRouter.videoPlayerPath));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A standard large play button for media details.
class LargePlayButton extends StatelessWidget {
  const LargePlayButton({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const PlaycadoIcon(PlaycadoIcons.play, size: 28),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class _MediaActionButton extends StatelessWidget {
  const _MediaActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onPressed,
    this.fontSize = 14,
  });
  final PlaycadoIcons icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return SizedBox(
      height: 48,
      child: isPrimary
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: PlaycadoIcon(icon, size: 24),
              label: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: shape,
                elevation: 0,
              ),
            )
          : FilledButton.tonalIcon(
              onPressed: onPressed,
              icon: PlaycadoIcon(icon, size: 20),
              label: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: shape,
                elevation: 0,
                backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                foregroundColor: colorScheme.onSurface,
              ),
            ),
    );
  }
}
