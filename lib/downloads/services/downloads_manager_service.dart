import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:rxdart/rxdart.dart';
import 'package:playcado/downloads/models/download_item.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/services/logger_service.dart';
import 'package:playcado/services/media_url/media_url_service.dart';

class DownloadsManagerService {
  DownloadsManagerService({required MediaUrlService urlGenerator})
    : _urlGenerator = urlGenerator {
    unawaited(_init());
  }
  final MediaUrlService _urlGenerator;
  final _controller = StreamController<List<DownloadItem>>.broadcast();
  final Map<String, DownloadItem> _downloadItems = {};
  StreamSubscription<TaskUpdate>? _updatesSubscription;

  bool _initialized = false;

  /// Tracks IDs currently being deleted to prevent race conditions
  /// where terminal updates resurrect the item in the UI.
  final Set<String> _processingDeletions = {};

  Stream<List<DownloadItem>> get downloads =>
      _controller.stream.throttleTime(const Duration(milliseconds: 250));
  List<DownloadItem> get currentDownloads => _downloadItems.values.toList();

  void dispose() {
    _initialized = false;
    unawaited(_updatesSubscription?.cancel());
    unawaited(_controller.close());
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await FileDownloader().configure(
        globalConfig: [(Config.requestTimeout, const Duration(seconds: 100))],
      );

      _updatesSubscription = FileDownloader().updates.listen(_onUpdate);

      await FileDownloader().trackTasks();
      await FileDownloader().start();

      final records = await FileDownloader().database.allRecords();

      for (final record in records) {
        try {
          if (record.task.metaData.isNotEmpty) {
            final jsonMap =
                jsonDecode(record.task.metaData) as Map<String, dynamic>;
            final item = DownloadItem.fromJson(jsonMap);
            final path = await record.task.filePath();

            _downloadItems[record.taskId] = item.copyWith(
              status: _mapStatus(record.status),
              progress: record.progress,
              localPath: path,
            );
          }
        } on Exception catch (e, s) {
          LoggerService.downloads.warning(
            'Failed to parse download record: ${record.taskId}',
            e,
            s,
          );
        }
      }
      if (_downloadItems.isNotEmpty) _emit();
    } on Exception catch (e, s) {
      LoggerService.downloads.severe(
        'DownloadsManagerService init failed',
        e,
        s,
      );
    }
  }

  DownloadStatus _mapStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.enqueued:
      case TaskStatus.waitingToRetry:
        return DownloadStatus.queued;
      case TaskStatus.running:
        return DownloadStatus.downloading;
      case TaskStatus.complete:
        return DownloadStatus.completed;
      case TaskStatus.paused:
        return DownloadStatus.paused;
      case TaskStatus.canceled:
      case TaskStatus.failed:
      case TaskStatus.notFound:
        return DownloadStatus.error;
    }
  }

  Future<void> addMediaDownload(MediaItem item) async {
    final downloadItem = DownloadItem(
      id: item.id,
      name: item.formattedFileName,
      overview: item.overview,
      imageUrl: _urlGenerator.getImageUrl(item.id),
      type: item.type,
      productionYear: item.productionYear,
      seriesName: item.seriesName,
      indexNumber: item.indexNumber,
      parentIndexNumber: item.parentIndexNumber,
      downloadUrl: _urlGenerator.getDownloadUrl(item.id),
      localPath: '',
    );

    return addDownload(downloadItem);
  }

  Future<void> addDownload(DownloadItem item) async {
    final task = DownloadTask(
      taskId: item.id,
      url: item.downloadUrl,
      filename: '${item.id}.mp4',
      baseDirectory: BaseDirectory.applicationSupport,
      updates: Updates.statusAndProgress,
      allowPause: true,
    );

    final absolutePath = await task.filePath();
    final itemWithPath = item.copyWith(
      localPath: absolutePath,
      status: DownloadStatus.queued,
    );

    final metaString = jsonEncode(itemWithPath.toJson());
    final taskWithMeta = task.copyWith(metaData: metaString);

    _downloadItems[item.id] = itemWithPath;
    _emit();

    try {
      await FileDownloader().enqueue(taskWithMeta);
    } catch (e, s) {
      LoggerService.downloads.severe('Failed to enqueue task', e, s);
      _downloadItems.remove(item.id);
      _emit();
      rethrow;
    }
  }

  /// Cancels and completely removes a download.
  ///
  /// The order of operations is critical here to prevent
  /// "resurrection" of the task in the UI via the stream listener.
  Future<void> deleteDownload(String id) async {
    _processingDeletions.add(id);

    try {
      final item = _downloadItems[id];

      if (item != null && item.localPath.isNotEmpty) {
        final file = File(item.localPath);
        if (file.existsSync()) {
          await file.delete();
        }
      }

      _downloadItems.remove(id);
      _emit();

      await FileDownloader().database.deleteRecordWithId(id);
      await FileDownloader().cancelTaskWithId(id);
    } catch (e, s) {
      LoggerService.downloads.severe('Failed to delete download', e, s);
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        _processingDeletions.remove(id);
      });
    }
  }

  Future<void> pauseDownload(String id) async {
    final task = await FileDownloader().taskForId(id);
    if (task is DownloadTask) {
      await FileDownloader().pause(task);
    }
  }

  Future<void> resumeDownload(String id) async {
    final task = await FileDownloader().taskForId(id);
    if (task is DownloadTask) {
      await FileDownloader().resume(task);
    }
  }

  Future<void> clearAll() async {
    _downloadItems.clear();
    _emit();

    await FileDownloader().database.deleteAllRecords();
    await FileDownloader().cancelAll();
  }

  Future<void> _onUpdate(TaskUpdate update) async {
    final taskId = update.task.taskId;

    if (_processingDeletions.contains(taskId)) return;

    if (update is TaskStatusUpdate && _isTerminalStatus(update.status)) {
      await _handleTerminalStatus(taskId);
      return;
    }

    final item = await _getOrCreateItem(taskId, update);
    if (item == null) return;

    final updatedItem = _updateItem(item, update);
    if (updatedItem == null) return;

    _downloadItems[taskId] = updatedItem;
    _emit();
  }

  bool _isTerminalStatus(TaskStatus status) {
    return status == TaskStatus.canceled || status == TaskStatus.notFound;
  }

  Future<void> _handleTerminalStatus(String taskId) async {
    _downloadItems.remove(taskId);
    _emit();
    await FileDownloader().database.deleteRecordWithId(taskId);
  }

  /// Gets the item from the cache or creates it from the database
  Future<DownloadItem?> _getOrCreateItem(
    String taskId,
    TaskUpdate update,
  ) async {
    final existing = _downloadItems[taskId];
    if (existing != null) return existing;

    LoggerService.downloads.info('Item not in memory cache: $taskId');

    final record = await FileDownloader().database.recordForId(taskId);

    if (record == null) {
      LoggerService.downloads.info('No record exists for $taskId');
      return null;
    }

    if (update.task.metaData.isEmpty) return null;

    try {
      LoggerService.downloads.info(
        'Reconstructing item from metadata: $taskId',
      );

      final jsonMap = jsonDecode(update.task.metaData) as Map<String, dynamic>;
      final path = await update.task.filePath();
      final item = DownloadItem.fromJson(jsonMap).copyWith(localPath: path);
      _downloadItems[taskId] = item;
      return item;
    } on Exception catch (_) {
      LoggerService.downloads.warning(
        'Failed to reconstruct item from metadata: $taskId',
      );
      return null;
    }
  }

  /// Applies an update to the item
  DownloadItem? _updateItem(DownloadItem item, TaskUpdate update) {
    switch (update) {
      case TaskStatusUpdate():
        LoggerService.downloads.info(
          'Status update: ${update.task.taskId} → ${update.status}',
        );
        final status = _mapStatus(update.status);
        return item.copyWith(
          status: status,
          progress: status == DownloadStatus.completed ? 1.0 : item.progress,
          networkSpeed: status == DownloadStatus.completed
              ? 0
              : item.networkSpeed,
        );

      case TaskProgressUpdate():
        LoggerService.downloads.info(
          'Progress update: ${update.task.taskId} → ${update.progress}',
        );

        final total = update.expectedFileSize > 0
            ? update.expectedFileSize
            : item.totalBytes;

        final received = update.progress >= 0
            ? (total * update.progress).round()
            : item.receivedBytes;

        return item.copyWith(
          progress: update.progress >= 0 ? update.progress : item.progress,
          networkSpeed: update.networkSpeed > 0
              ? update.networkSpeed * 1024 * 1024
              : 0,
          totalBytes: total,
          receivedBytes: received,
        );
    }
  }

  void _emit() => _controller.add(_downloadItems.values.toList());
}
