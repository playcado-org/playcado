import 'package:jellyfin_dart/jellyfin_dart.dart';
import 'package:playcado/media/data/media_remote_data_source.dart';
import 'package:playcado/services/logger_service.dart';

class PlayerTrackerRepository {
  PlayerTrackerRepository({required MediaRemoteDataSource dataSource})
    : _dataSource = dataSource;

  final MediaRemoteDataSource _dataSource;

  Future<void> reportPlaybackStart(String itemId) async {
    try {
      LoggerService.playerTracker.fine('Reporting playback START: $itemId');
      await _dataSource.reportPlaybackStart(
        itemId: itemId,
        playMethod: PlayMethod.directPlay,
      );
    } on Exception catch (e) {
      LoggerService.playerTracker.warning('Failed to report playback start', e);
    }
  }

  Future<void> reportPlaybackProgress({
    required String itemId,
    required int positionTicks,
    bool isPaused = false,
  }) async {
    try {
      LoggerService.playerTracker.finest('Reporting progress: $itemId @ $positionTicks');
      await _dataSource.reportPlaybackProgress(
        itemId: itemId,
        positionTicks: positionTicks,
        isPaused: isPaused,
      );
    } on Exception catch (e) {
      LoggerService.playerTracker.finer('Failed to report playback progress', e);
    }
  }

  Future<void> reportPlaybackStopped({
    required String itemId,
    required int positionTicks,
  }) async {
    try {
      LoggerService.playerTracker.fine('Reporting playback STOPPED: $itemId');
      await _dataSource.reportPlaybackStopped(
        itemId: itemId,
        positionTicks: positionTicks,
      );
    } on Exception catch (e) {
      LoggerService.playerTracker.warning('Failed to report playback stop', e);
    }
  }

  Future<void> togglePlayedStatus(
    String itemId, {
    required bool isPlayed,
  }) async {
    try {
      final userId = await _dataSource.getCurrentUserId();
      if (userId == null) return;

      if (isPlayed) {
        await _dataSource.markPlayedItem(userId: userId, itemId: itemId);
      } else {
        await _dataSource.markUnplayedItem(userId: userId, itemId: itemId);
      }
    } on Exception catch (e) {
      LoggerService.playerTracker.warning('Failed to toggle played status', e);
    }
  }
}
