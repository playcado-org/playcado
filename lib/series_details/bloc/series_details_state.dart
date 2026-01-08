part of 'series_details_bloc.dart';

class SeriesDetailsState extends Equatable {
  const SeriesDetailsState({
    this.seasons = const StatusInitial(),
    this.episodes = const StatusInitial(),
    this.nextEpisode = const StatusInitial(),
    this.series = const StatusInitial(),
    this.expandedSeasonId,
    this.isResuming = false,
    this.selectedEpisode,
    this.isSelectedEpisodeLoading = false,
  });
  final StatusWrapper<List<MediaItem>> seasons;
  final StatusWrapper<Map<String, List<MediaItem>>> episodes;
  final StatusWrapper<MediaItem> nextEpisode;
  final StatusWrapper<MediaItem> series;
  final String? expandedSeasonId;
  final bool isResuming;
  final MediaItem? selectedEpisode;
  final bool isSelectedEpisodeLoading;

  bool get isNextEpisodeLoading => nextEpisode.isLoading;

  SeriesDetailsState copyWith({
    StatusWrapper<List<MediaItem>>? seasons,
    StatusWrapper<Map<String, List<MediaItem>>>? episodes,
    StatusWrapper<MediaItem>? nextEpisode,
    StatusWrapper<MediaItem>? series,
    String? expandedSeasonId,
    bool clearExpandedSeasonId = false,
    bool? isResuming,
    ValueGetter<MediaItem?>? selectedEpisode,
    bool? isSelectedEpisodeLoading,
  }) {
    return SeriesDetailsState(
      seasons: seasons ?? this.seasons,
      episodes: episodes ?? this.episodes,
      nextEpisode: nextEpisode ?? this.nextEpisode,
      series: series ?? this.series,
      expandedSeasonId: clearExpandedSeasonId
          ? null
          : (expandedSeasonId ?? this.expandedSeasonId),
      isResuming: isResuming ?? this.isResuming,
      selectedEpisode: selectedEpisode != null
          ? selectedEpisode()
          : this.selectedEpisode,
      isSelectedEpisodeLoading:
          isSelectedEpisodeLoading ?? this.isSelectedEpisodeLoading,
    );
  }

  @override
  List<Object?> get props => [
    seasons,
    episodes,
    nextEpisode,
    series,
    expandedSeasonId,
    isResuming,
    selectedEpisode,
    isSelectedEpisodeLoading,
  ];
}
