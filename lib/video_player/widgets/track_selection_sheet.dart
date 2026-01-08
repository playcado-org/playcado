import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/widgets/widgets.dart';

class TrackSelectionSheet extends StatefulWidget {
  const TrackSelectionSheet({required this.player, super.key});
  final Player player;

  @override
  State<TrackSelectionSheet> createState() => _TrackSelectionSheetState();
}

class _TrackSelectionSheetState extends State<TrackSelectionSheet> {
  @override
  Widget build(BuildContext context) {
    // We access tracks directly from state.
    // In a production app, wrapping this in a StreamBuilder listening to
    // widget.player.stream.tracks would be more reactive,
    // but looking at state is sufficient for the modal's lifespan.
    final tracks = widget.player.state.tracks;
    final audioTracks = tracks.audio;
    final subtitleTracks = tracks.subtitle;

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
                  _buildTrackList<AudioTrack>(
                    context,
                    audioTracks,
                    widget.player.state.track.audio,
                    (track) async {
                      await widget.player.setAudioTrack(track);
                      setState(() {});
                    },
                    labelBuilder: _audioLabel,
                  ),
                  _buildTrackList<SubtitleTrack>(
                    context,
                    subtitleTracks,
                    widget.player.state.track.subtitle,
                    (track) async {
                      await widget.player.setSubtitleTrack(track);
                      setState(() {});
                    },
                    labelBuilder: _subtitleLabel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackList<T>(
    BuildContext context,
    List<T> tracks,
    T current,
    ValueChanged<T> onSelect, {
    required String Function(T) labelBuilder,
  }) {
    if (tracks.isEmpty) {
      return Center(child: Text(context.l10n.noTracksAvailable));
    }

    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isSelected = track == current;

        return ListTile(
          title: Text(labelBuilder(track)),
          trailing: isSelected
              ? PlaycadoIcon(
                  PlaycadoIcons.check,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
          onTap: () => onSelect(track),
        );
      },
    );
  }

  String _audioLabel(AudioTrack track) {
    if (track.id == 'no') return context.l10n.off;
    if (track.id == 'auto') return context.l10n.auto;
    return '${track.language ?? context.l10n.unknown}'
        ' ${track.title != null ? "(${track.title})" : ""}';
  }

  String _subtitleLabel(SubtitleTrack track) {
    if (track.id == 'no') return context.l10n.off;
    if (track.id == 'auto') return context.l10n.auto;
    return '${track.language ?? context.l10n.unknown}'
        ' ${track.title != null ? "(${track.title})" : ""}';
  }
}
