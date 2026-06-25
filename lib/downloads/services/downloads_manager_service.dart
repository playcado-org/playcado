import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:playcado/downloads/data/downloaded_media_database.dart';
import 'package:playcado/downloads/models/active_download.dart';
import 'package:playcado/downloads/models/downloaded_media_item.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/services/jellyfin_client_service.dart';
import 'package:playcado/services/logger_service.dart';
import 'package:playcado/services/media_url/media_url_service.dart';

class DownloadsManagerService {
  DownloadsManagerService({
    required MediaUrlService urlService,
    required JellyfinClientService jellyfinClient,
    required DownloadedMediaDatabase database,
  }) : _urlService = urlService,
       _jellyfinClient = jellyfinClient,
       _database = database {
    _init();
  }

  final MediaUrlService _urlService;
  final JellyfinClientService _jellyfinClient;
  final DownloadedMediaDatabase _database;

  final Map<String, ActiveDownload> _activeCache = {};
  final _activeController = StreamController<List<ActiveDownload>>.broadcast();

  Stream<List<ActiveDownload>> get activeDownloadsStream =>
      _activeController.stream;
  Stream<List<DownloadedMediaItem>> get offlineLibraryStream =>
      _database.watchOfflineLibrary();

  Future<void> _init() async {
    await FileDownloader().configure(
      globalConfig: [
        (Config.requestTimeout, const Duration(seconds: 100)),
        (Config.runInForegroundIfFileLargerThan, 500),
      ],
    );

    FileDownloader().updates.listen(_onUpdate);

    await FileDownloader().trackTasks();
    final records = await FileDownloader().database.allRecords();

    for (final record in records) {
      if (record.status == TaskStatus.complete) continue;

      if (record.task.metaData.isNotEmpty) {
        final media = MediaItem.fromJson(
          jsonDecode(record.task.metaData) as Map<String, dynamic>,
        );
        _activeCache[record.taskId] = ActiveDownload(
          media: media,
          status: _mapStatus(record.status),
          progress: record.progress,
        );
      }
    }
    _emitActive();
  }

  Future<void> addMediaDownload(MediaItem item) async {
    _activeCache[item.id] = ActiveDownload(media: item);
    _emitActive();

    final token = _jellyfinClient.accessToken;
    final deviceId = _jellyfinClient.deviceId;
    final headers = {
      'X-Emby-Authorization':
          'MediaBrowser Client="Playcado", Device="Flutter", DeviceId="$deviceId", Version="1.0.0", Token="$token"',
    };

    final task = DownloadTask(
      taskId: item.id,
      url: _urlService.getDownloadUrl(item.id),
      filename: '${item.id}.mp4',
      headers: headers,
      baseDirectory: BaseDirectory.applicationSupport,
      directory: 'offline_media',
      updates: Updates.statusAndProgress,
      allowPause: true,
      retries: 3,
      metaData: jsonEncode(item.toJson()),
    );

    await FileDownloader().enqueue(task);
  }

  Future<void> deleteDownload(String id) async {
    LoggerService.downloads.info('Deleting media: $id');

    await _database.removeOfflineMedia(id);

    _activeCache.remove(id);
    _emitActive();

    await FileDownloader().cancelTaskWithId(id);
    await FileDownloader().database.deleteRecordWithId(id);

    try {
      final task = await FileDownloader().taskForId(id);
      if (task != null) {
        final path = await task.filePath();
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      LoggerService.downloads.warning('Failed to delete file for $id', e);
    }
  }

  Future<void> _onUpdate(TaskUpdate update) async {
    final taskId = update.task.taskId;

    if (!_activeCache.containsKey(taskId)) return;

    final cachedItem = _activeCache[taskId]!;

    if (update is TaskStatusUpdate) {
      if (update.status == TaskStatus.complete) {
        final filePath = await update.task.filePath();
        final file = File(filePath);
        final size = await file.exists() ? await file.length() : 0;

        await _database.saveOfflineMedia(
          DownloadedMediaItem(
            media: cachedItem.media,
            localPath: filePath,
            totalBytes: size,
            downloadedAt: DateTime.now(),
          ),
        );

        _activeCache.remove(taskId);
        FileDownloader().database.deleteRecordWithId(taskId);
      } else if (update.status == TaskStatus.canceled) {
        _activeCache.remove(taskId);
      } else {
        String? errorReason;
        if (update.status == TaskStatus.failed ||
            update.status == TaskStatus.notFound) {
          if (update.exception is TaskHttpException) {
            final code =
                (update.exception as TaskHttpException).httpResponseCode;
            errorReason = code == 401 ? 'Auth expired' : 'Server Error ($code)';
          } else {
            errorReason = update.exception?.description ?? 'Network error';
          }
        }

        _activeCache[taskId] = cachedItem.copyWith(
          status: _mapStatus(update.status),
          errorReason: errorReason,
        );
      }
    } else if (update is TaskProgressUpdate) {
      _activeCache[taskId] = cachedItem.copyWith(
        progress: update.progress,
        networkSpeed: update.networkSpeed,
        totalBytes: update.expectedFileSize,
        receivedBytes: (update.expectedFileSize * update.progress).round(),
      );
    }

    _emitActive();
  }

  ActiveDownloadStatus _mapStatus(TaskStatus status) {
    return switch (status) {
      TaskStatus.enqueued ||
      TaskStatus.waitingToRetry => ActiveDownloadStatus.queued,
      TaskStatus.running => ActiveDownloadStatus.downloading,
      TaskStatus.paused => ActiveDownloadStatus.paused,
      TaskStatus.failed || TaskStatus.notFound => ActiveDownloadStatus.error,
      _ => ActiveDownloadStatus.queued,
    };
  }

  void _emitActive() => _activeController.add(_activeCache.values.toList());

  Future<void> pauseDownload(String id) async {
    final task = await FileDownloader().taskForId(id);
    if (task is DownloadTask) await FileDownloader().pause(task);
  }

  Future<void> resumeDownload(String id) async {
    final task = await FileDownloader().taskForId(id);
    if (task is DownloadTask) await FileDownloader().resume(task);
  }

  void dispose() {
    _activeController.close();
  }

  Future<void> clearAll() async {
    _activeCache.clear();
    _emitActive();

    final records = await FileDownloader().database.allRecords();
    for (final record in records) {
      try {
        final path = await record.task.filePath();
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }

    await FileDownloader().database.deleteAllRecords();
    await FileDownloader().cancelAll();
  }
}
