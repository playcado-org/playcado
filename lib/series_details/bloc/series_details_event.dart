part of 'series_details_bloc.dart';

abstract class SeriesDetailsEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class SeriesDetailsStarted extends SeriesDetailsEvent {
  SeriesDetailsStarted({required this.item});
  final MediaItem item;
  @override
  List<Object> get props => [item];
}

class FetchSeasons extends SeriesDetailsEvent {
  FetchSeasons({required this.seriesId});
  final String seriesId;
  @override
  List<Object> get props => [seriesId];
}

class FetchEpisodes extends SeriesDetailsEvent {
  FetchEpisodes({required this.seriesId, required this.seasonId});
  final String seriesId;
  final String seasonId;

  @override
  List<Object> get props => [seriesId, seasonId];
}

class FetchNextEpisode extends SeriesDetailsEvent {
  FetchNextEpisode({required this.seriesId});
  final String seriesId;
  @override
  List<Object> get props => [seriesId];
}

class FetchSeriesMetadata extends SeriesDetailsEvent {
  FetchSeriesMetadata({required this.seriesId});
  final String seriesId;
  @override
  List<Object> get props => [seriesId];
}

class CollapseSeason extends SeriesDetailsEvent {}

class FetchItemDetails extends SeriesDetailsEvent {
  FetchItemDetails({required this.itemId});
  final String itemId;
  @override
  List<Object> get props => [itemId];
}

class FetchSelectedEpisodeDetails extends SeriesDetailsEvent {
  FetchSelectedEpisodeDetails({required this.episodeId});
  final String episodeId;
  @override
  List<Object> get props => [episodeId];
}

class TogglePlayedStatus extends SeriesDetailsEvent {}

class SelectEpisode extends SeriesDetailsEvent {
  SelectEpisode({required this.episode});
  final MediaItem episode;
  @override
  List<Object> get props => [episode];
}

/// Updates the local playback position for an item in the state
class UpdateLocalPlaybackProgress extends SeriesDetailsEvent {
  UpdateLocalPlaybackProgress({
    required this.itemId,
    required this.positionTicks,
  });
  final String itemId;
  final int positionTicks;

  @override
  List<Object> get props => [itemId, positionTicks];
}
