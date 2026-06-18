import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/status_wrapper.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/media/repos/library_repository.dart';
import 'package:playcado/playback/repos/playback_tracker.dart';
import 'package:playcado/services/logger_service.dart';

part 'series_details_event.dart';
part 'series_details_state.dart';

class SeriesDetailsBloc extends Bloc<SeriesDetailsEvent, SeriesDetailsState> {
  SeriesDetailsBloc({
    required LibraryRepository libraryRepository,
    required PlaybackTracker playbackTracker,
  }) : _libraryRepository = libraryRepository,
       _playbackTracker = playbackTracker,
       super(const SeriesDetailsState()) {
    on<SeriesDetailsStarted>(_onSeriesDetailsStarted);
    on<FetchSeasons>(_onFetchSeasons);
    on<FetchEpisodes>(_onFetchEpisodes);
    on<FetchNextEpisode>(_onFetchNextEpisode);
    on<FetchSeriesMetadata>(_onFetchSeriesMetadata);
    on<CollapseSeason>(_onCollapseSeason);
    on<FetchItemDetails>(_onFetchItemDetails);
    on<FetchSelectedEpisodeDetails>(_onFetchSelectedEpisodeDetails);
    on<TogglePlayedStatus>(_onTogglePlayedStatus);
    on<SelectEpisode>(_onSelectEpisode);
    on<UpdateLocalPlaybackProgress>(_onUpdateLocalPlaybackProgress);
  }
  final LibraryRepository _libraryRepository;
  final PlaybackTracker _playbackTracker;

  Future<void> _onSeriesDetailsStarted(
    SeriesDetailsStarted event,
    Emitter<SeriesDetailsState> emit,
  ) async {
    final item = event.item;
    final isEpisode = item.type == MediaItemType.episode;
    final seriesId = isEpisode ? item.seriesId : item.id;

    if (seriesId == null) return;

    emit(
      state.copyWith(
        series: const StatusLoading(),
        seasons: const StatusLoading(),
        episodes: const StatusLoading(),
        nextEpisode: const StatusLoading(),
        isSelectedEpisodeLoading: isEpisode,
      ),
    );

    MediaItem? seriesMetadata;
    List<MediaItem> seasons;
    try {
      seriesMetadata = await _libraryRepository.getItem(seriesId);
      seasons = await _libraryRepository.getSeasons(seriesId);
    } on Exception catch (error) {
      LoggerService.media.severe('Failed to initialize series details', error);
      emit(
        state.copyWith(
          series: StatusError(error.toString()),
          seasons: const StatusError('Failed to load'),
          episodes: const StatusError('Failed to load'),
          nextEpisode: const StatusError('Failed to load'),
        ),
      );
      return;
    }

    MediaItem? nextUp;
    MediaItem? selectedEp;

    if (isEpisode) {
      try {
        selectedEp = await _libraryRepository.getItem(item.id);
      } on Exception {
        selectedEp = null;
      }
    } else {
      nextUp = await _libraryRepository.getNextEpisode(seriesId);
      nextUp ??= await _libraryRepository.getFirstEpisode(seriesId);
    }

    String? seasonIdToLoad;
    if (isEpisode) {
      seasonIdToLoad = item.seasonId;
    } else if (nextUp != null && nextUp.seasonId != null) {
      seasonIdToLoad = nextUp.seasonId;
    } else if (seasons.isNotEmpty) {
      seasonIdToLoad = seasons.first.id;
    }

    var initialEpisodes = <MediaItem>[];
    if (seasonIdToLoad != null) {
      try {
        initialEpisodes = await _libraryRepository.getEpisodes(
          seriesId: seriesId,
          seasonId: seasonIdToLoad,
        );
      } on Exception catch (error) {
        LoggerService.media.severe('Failed to fetch episodes', error);
      }
    }

    final episodesMap = <String, List<MediaItem>>{};
    if (seasonIdToLoad != null) {
      episodesMap[seasonIdToLoad] = initialEpisodes;
    }

    emit(
      state.copyWith(
        series: StatusSuccess(seriesMetadata),
        seasons: StatusSuccess(seasons),
        episodes: StatusSuccess(episodesMap),
        nextEpisode: nextUp != null
            ? StatusSuccess(nextUp)
            : const StatusInitial(),
        selectedEpisode: isEpisode ? () => selectedEp : null,
        expandedSeasonId: seasonIdToLoad,
        isSelectedEpisodeLoading: false,
      ),
    );
  }

  Future<void> _onFetchSeasons(
    FetchSeasons event,
    Emitter<SeriesDetailsState> emit,
  ) async {
    emit(state.copyWith(seasons: const StatusLoading()));

    try {
      final seasons = await _libraryRepository.getSeasons(event.seriesId);
      emit(state.copyWith(seasons: StatusSuccess(seasons)));
    } on Exception catch (error) {
      LoggerService.media.severe('Failed to fetch seasons', error);
      emit(state.copyWith(seasons: StatusError(error.toString())));
    }
  }

  Future<void> _onFetchEpisodes(
    FetchEpisodes event,
    Emitter<SeriesDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        episodes: StatusLoading(previousValue: state.episodes.value),
        expandedSeasonId: event.seasonId,
      ),
    );

    try {
      final episodes = await _libraryRepository.getEpisodes(
        seriesId: event.seriesId,
        seasonId: event.seasonId,
      );
      final currentEpisodes = Map<String, List<MediaItem>>.from(
        state.episodes.value ?? {},
      );
      currentEpisodes[event.seasonId] = episodes;
      emit(state.copyWith(episodes: StatusSuccess(currentEpisodes)));
    } on Exception catch (error) {
      LoggerService.media.severe('Failed to fetch episodes', error);
      emit(state.copyWith(episodes: StatusError(error.toString())));
    }
  }

  Future<void> _onFetchNextEpisode(
    FetchNextEpisode event,
    Emitter<SeriesDetailsState> emit,
  ) async {
    emit(state.copyWith(nextEpisode: const StatusLoading()));

    try {
      List<MediaItem> resumeItems;
      try {
        resumeItems = await _libraryRepository.getResumeItems();
      } on Exception {
        resumeItems = [];
      }

      final resumableEpisode = resumeItems.cast<MediaItem?>().firstWhere(
        (item) => item?.seriesId == event.seriesId,
        orElse: () => null,
      );

      if (resumableEpisode != null) {
        emit(
          state.copyWith(
            nextEpisode: StatusSuccess(resumableEpisode),
            isResuming: true,
          ),
        );
        return;
      }

      var episode = await _libraryRepository.getNextEpisode(event.seriesId);
      episode ??= await _libraryRepository.getFirstEpisode(event.seriesId);

      emit(
        state.copyWith(
          nextEpisode: episode != null
              ? StatusSuccess(episode)
              : const StatusInitial(),
          isResuming: false,
        ),
      );
    } on Exception catch (e) {
      LoggerService.media.severe('Failed to fetch next episode', e);
      emit(state.copyWith(nextEpisode: StatusError(e.toString())));
    }
  }

  Future<void> _onFetchSeriesMetadata(
    FetchSeriesMetadata event,
    Emitter<SeriesDetailsState> emit,
  ) async {
    emit(state.copyWith(series: const StatusLoading()));

    try {
      final series = await _libraryRepository.getItem(event.seriesId);
      emit(state.copyWith(series: StatusSuccess(series)));
    } on Exception catch (error) {
      LoggerService.media.severe('Failed to fetch series metadata', error);
      emit(state.copyWith(series: StatusError(error.toString())));
    }
  }

  void _onCollapseSeason(
    CollapseSeason event,
    Emitter<SeriesDetailsState> emit,
  ) {
    emit(state.copyWith(clearExpandedSeasonId: true));
  }

  Future<void> _onFetchItemDetails(
    FetchItemDetails event,
    Emitter<SeriesDetailsState> emit,
  ) async {
    emit(state.copyWith(series: const StatusLoading()));

    try {
      final item = await _libraryRepository.getItem(event.itemId);
      emit(state.copyWith(series: StatusSuccess(item)));
    } on Exception catch (error) {
      LoggerService.media.severe('Failed to fetch item details', error);
      emit(state.copyWith(series: StatusError(error.toString())));
    }
  }

  Future<void> _onFetchSelectedEpisodeDetails(
    FetchSelectedEpisodeDetails event,
    Emitter<SeriesDetailsState> emit,
  ) async {
    emit(state.copyWith(isSelectedEpisodeLoading: true));

    try {
      final item = await _libraryRepository.getItem(event.episodeId);
      emit(
        state.copyWith(
          selectedEpisode: () => item,
          isSelectedEpisodeLoading: false,
        ),
      );
    } on Exception catch (error) {
      LoggerService.media.severe(
        'Failed to fetch selected episode details',
        error,
      );
      emit(state.copyWith(isSelectedEpisodeLoading: false));
    }
  }

  Future<void> _onTogglePlayedStatus(
    TogglePlayedStatus event,
    Emitter<SeriesDetailsState> emit,
  ) async {
    final currentItem = state.series.value;
    if (currentItem == null) return;
    final newPlayedStatus = !currentItem.isPlayed;
    final updatedItem = currentItem.copyWith(isPlayed: newPlayedStatus);
    emit(state.copyWith(series: StatusSuccess(updatedItem)));
    try {
      await _playbackTracker.togglePlayedStatus(
        currentItem.id,
        isPlayed: newPlayedStatus,
      );
    } on Exception catch (e, stackTrace) {
      LoggerService.media.severe(
        'Failed to toggle played status',
        e,
        stackTrace,
      );
      emit(state.copyWith(series: StatusSuccess(currentItem)));
    }
  }

  void _onSelectEpisode(SelectEpisode event, Emitter<SeriesDetailsState> emit) {
    emit(state.copyWith(selectedEpisode: () => event.episode));
  }

  void _onUpdateLocalPlaybackProgress(
    UpdateLocalPlaybackProgress event,
    Emitter<SeriesDetailsState> emit,
  ) {
    final seriesItem = state.series.value;
    if (seriesItem != null && seriesItem.id == event.itemId) {
      final updated = seriesItem.copyWith(
        playbackPositionTicks: event.positionTicks,
      );
      emit(state.copyWith(series: StatusSuccess(updated)));
    }

    final nextEp = state.nextEpisode.value;
    if (nextEp != null && nextEp.id == event.itemId) {
      final updated = nextEp.copyWith(
        playbackPositionTicks: event.positionTicks,
      );
      emit(state.copyWith(nextEpisode: StatusSuccess(updated)));
    }

    final selectedEp = state.selectedEpisode;
    if (selectedEp != null && selectedEp.id == event.itemId) {
      final updated = selectedEp.copyWith(
        playbackPositionTicks: event.positionTicks,
      );
      emit(state.copyWith(selectedEpisode: () => updated));
    }
  }
}
