import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/formatters.dart';
import 'package:playcado/video_player/bloc/video_player_bloc.dart';

class VideoSlider extends StatelessWidget {
  const VideoSlider({
    super.key,
    this.onInteractionStart,
    this.onInteractionEnd,
  });
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoPlayerBloc, VideoPlayerState>(
      buildWhen: (prev, curr) =>
          prev.position != curr.position || prev.duration != curr.duration,
      builder: (context, state) {
        final position = state.position;
        final totalDuration = state.duration;
        final max = totalDuration.inMilliseconds.toDouble();
        final value = position.inMilliseconds.toDouble().clamp(0.0, max);

        return Row(
          children: [
            Text(
              Formatters.formatTime(position),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: value,
                  max: max > 0 ? max : 1.0,
                  onChanged: (newValue) {
                    onInteractionStart?.call();
                    context.read<VideoPlayerBloc>().add(
                      PlayerSeekRequested(
                        Duration(milliseconds: newValue.toInt()),
                      ),
                    );
                  },
                  onChangeEnd: (_) {
                    onInteractionEnd?.call();
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              Formatters.formatTime(totalDuration),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}
