import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/player/services/local_playback_service.dart';
import 'package:playcado/widgets/widgets.dart';

class TrackSelectionSheet extends StatefulWidget {
  const TrackSelectionSheet({required this.engine, super.key});
  final LocalPlaybackService engine;

  @override
  State<TrackSelectionSheet> createState() => _TrackSelectionSheetState();
}

class _TrackSelectionSheetState extends State<TrackSelectionSheet> {
  @override
  Widget build(BuildContext context) {
    final audioTracks = widget.engine.audioTracks;
    final subtitleTracks = widget.engine.subtitleTracks;
    final currentAudio = widget.engine.currentAudioTrackIndex;
    final currentSubtitle = widget.engine.currentSubtitleTrackIndex;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: context.l10n.audio),
                Tab(text: context.l10n.subtitles),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTrackList(
                    context,
                    audioTracks,
                    currentAudio,
                    (index) {
                      context.read<PlayerBloc>().add(
                        PlayerTrackSelected(
                          type: TrackType.audio,
                          index: index,
                        ),
                      );
                      setState(() {});
                    },
                    labelBuilder: (track) {
                      if (track.id == 'no') return context.l10n.off;
                      if (track.id == 'auto') return context.l10n.auto;
                      return '${track.language ?? context.l10n.unknown}'
                          ' ${track.title != null ? "(${track.title})" : ""}';
                    },
                  ),
                  _buildTrackList(
                    context,
                    subtitleTracks,
                    currentSubtitle,
                    (index) {
                      context.read<PlayerBloc>().add(
                        PlayerTrackSelected(
                          type: TrackType.subtitle,
                          index: index,
                        ),
                      );
                      setState(() {});
                    },
                    labelBuilder: (track) {
                      if (track.id == 'no') return context.l10n.off;
                      if (track.id == 'auto') return context.l10n.auto;
                      return '${track.language ?? context.l10n.unknown}'
                          ' ${track.title != null ? "(${track.title})" : ""}';
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackList(
    BuildContext context,
    List<dynamic> tracks,
    int currentIndex,
    ValueChanged<int> onSelect, {
    required String Function(dynamic) labelBuilder,
  }) {
    if (tracks.isEmpty) {
      return Center(child: Text(context.l10n.noTracksAvailable));
    }

    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isSelected = index == currentIndex;

        return ListTile(
          title: Text(labelBuilder(track)),
          trailing: isSelected
              ? PlaycadoIcon(
                  PlaycadoIcons.check,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          onTap: () => onSelect(index),
        );
      },
    );
  }
}
