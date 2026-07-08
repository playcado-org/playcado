import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:playcado/downloads/data/downloaded_media_database.dart';
import 'package:playcado/downloads/models/active_download.dart';
import 'package:playcado/downloads/models/downloaded_media_item.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/media/repositories/library_repository.dart';
import 'package:playcado/services/jellyfin_client_service.dart';
import 'package:playcado/services/logger_service.dart';
import 'package:playcado/services/media_url/media_url_service.dart';
import 'package:rxdart/rxdart.dart';

class DownloadsManagerService {
  DownloadsManagerService({
    required MediaUrlService urlService,
    required JellyfinClientService jellyfinClient,
    required DownloadedMediaDatabase database,
    required Stream<TaskUpdate> downloadUpdatesStream,
    required LibraryRepository libraryRepository,
  }) : _downloadUpdatesStream = downloadUpdatesStream,
       _urlService = urlService,
       _jellyfinClient = jellyfinClient,
       _database = database,
       _libraryRepository = libraryRepository;

  final MediaUrlService _urlService;
  final JellyfinClientService _jellyfinClient;
  final DownloadedMediaDatabase _database;
  final LibraryRepository _libraryRepository;
  final Stream<TaskUpdate> _downloadUpdatesStream;

  StreamSubscription<TaskUpdate>? _updatesSubscription;
  bool _initialized = false;

  final Map<String, ActiveDownload> _activeCache = {};
  final _activeController = BehaviorSubject<List<ActiveDownload>>.seeded([]);

  Stream<List<ActiveDownload>> get activeDownloadsStream => _activeController
      .throttleTime(const Duration(milliseconds: 200), trailing: true);
  Stream<List<DownloadedMediaItem>> get offlineLibraryStream =>
      _database.watchOfflineLibrary();

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    _updatesSubscription ??= _downloadUpdatesStream.listen(_onUpdate);

    await FileDownloader().trackTasks();
    final records = await FileDownloader().database.allRecords();

    for (final record in records) {
      if (record.status == TaskStatus.complete) continue;

      if (record.task.metaData.isNotEmpty) {
        final data = jsonDecode(record.task.metaData) as Map<String, dynamic>;
        final mediaData = data['media'] as Map<String, dynamic>;
        final media = MediaItem.fromJson(mediaData);
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

    MediaItem fullItem = item;
    try {
      fullItem = await _fetchFullItem(item.id);
    } catch (e) {
      LoggerService.downloads.warning(
        '[Download: MetadataFailed] [ItemId: ${item.id}] [Error: $e]',
      );
    }

    String? localPosterPath;
    String? localBackdropPath;
    try {
      localPosterPath = await _downloadImage(
        url: _urlService.getItemImageUrl(fullItem),
        itemId: fullItem.id,
        suffix: 'poster',
        width: 600,
      );
    } catch (e) {
      LoggerService.downloads.warning(
        '[Download: ImageFailed] [ItemId: ${fullItem.id}] [Type: poster] [Error: $e]',
      );
    }
    try {
      localBackdropPath = await _downloadImage(
        url: _urlService.getItemBackdropUrl(fullItem),
        itemId: fullItem.id,
        suffix: 'backdrop',
        width: 1280,
      );
    } catch (e) {
      LoggerService.downloads.warning(
        '[Download: ImageFailed] [ItemId: ${fullItem.id}] [Type: backdrop] [Error: $e]',
      );
    }
    try {
      final seriesId = fullItem.seriesId;
      if (seriesId != null && seriesId.isNotEmpty) {
        await _downloadImage(
          url: _urlService.getImageUrl(seriesId),
          itemId: seriesId,
          suffix: 'series_poster',
          width: 600,
        );
      }
    } catch (e) {
      LoggerService.downloads.warning(
        '[Download: ImageFailed] [ItemId: ${fullItem.id}] [Type: series_poster] [Error: $e]',
      );
    }
    if (fullItem.people case final people? when people.isNotEmpty) {
      for (final person in people) {
        try {
          await _downloadImage(
            url: _urlService.getImageUrl(person.id),
            itemId: person.id,
            suffix: 'cast',
            width: 200,
          );
        } catch (e) {
          LoggerService.downloads.warning(
            '[Download: ImageFailed] [ItemId: ${person.id}] [Type: cast] [Error: $e]',
          );
        }
      }
    }

    final metaDataMap = {
      'media': fullItem.toJson(),
      'localPosterPath': localPosterPath,
      'localBackdropPath': localBackdropPath,
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
      metaData: jsonEncode(metaDataMap),
    );

    await FileDownloader().enqueue(task);
  }

  Future<void> _onUpdate(TaskUpdate update) async {
    final taskId = update.task.taskId;

    if (!_activeCache.containsKey(taskId)) return;

    final cachedItem = _activeCache[taskId]!;

    if (update is TaskStatusUpdate) {
      LoggerService.downloads.fine(
        '[Download: StatusUpdate] [TaskId: $taskId] [Status: ${update.status.name}]',
      );
      if (update.status == TaskStatus.complete) {
        final filePath = await update.task.filePath();
        final file = File(filePath);
        final size = await file.exists() ? await file.length() : 0;

        LoggerService.downloads.info(
          '[Download: Completed] [TaskId: $taskId] [Path: $filePath] [Size: $size bytes]',
        );

        final metaDataMap =
            jsonDecode(update.task.metaData) as Map<String, dynamic>;
        final media = MediaItem.fromJson(
          metaDataMap['media'] as Map<String, dynamic>,
        );
        String? localPosterPath = metaDataMap['localPosterPath'] as String?;
        String? localBackdropPath = metaDataMap['localBackdropPath'] as String?;

        if (localPosterPath == null) {
          try {
            localPosterPath = await _downloadImage(
              url: _urlService.getItemImageUrl(media),
              itemId: media.id,
              suffix: 'poster',
              width: 600,
            );
          } catch (e) {
            LoggerService.downloads.warning(
              '[Download: ImageFailed] [ItemId: ${media.id}] [Type: poster] [Error: $e]',
            );
          }
        }
        if (localBackdropPath == null) {
          try {
            localBackdropPath = await _downloadImage(
              url: _urlService.getItemBackdropUrl(media),
              itemId: media.id,
              suffix: 'backdrop',
              width: 1280,
            );
          } catch (e) {
            LoggerService.downloads.warning(
              '[Download: ImageFailed] [ItemId: ${media.id}] [Type: backdrop] [Error: $e]',
            );
          }
        }

        try {
          final seriesId = media.seriesId;
          if (seriesId != null && seriesId.isNotEmpty) {
            await _downloadImage(
              url: _urlService.getImageUrl(seriesId),
              itemId: seriesId,
              suffix: 'series_poster',
              width: 600,
            );
          }
        } catch (e) {
          LoggerService.downloads.warning(
            '[Download: ImageFailed] [ItemId: ${media.id}] [Type: series_poster] [Error: $e]',
          );
        }

        if (media.people case final people? when people.isNotEmpty) {
          for (final person in people) {
            try {
              await _downloadImage(
                url: _urlService.getImageUrl(person.id),
                itemId: person.id,
                suffix: 'cast',
                width: 200,
              );
            } catch (e) {
              LoggerService.downloads.warning(
                '[Download: ImageFailed] [ItemId: ${person.id}] [Type: cast] [Error: $e]',
              );
            }
          }
        }

        await _database.saveOfflineMedia(
          DownloadedMediaItem(
            media: media,
            localPath: filePath,
            totalBytes: size,
            downloadedAt: DateTime.now(),
            localPosterPath: localPosterPath,
            localBackdropPath: localBackdropPath,
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

  void _emitActive() {
    if (!_activeController.isClosed) {
      _activeController.add(_activeCache.values.toList());
    }
  }

  Future<void> pauseDownload(String id) async {
    final task = await FileDownloader().taskForId(id);
    if (task is DownloadTask) await FileDownloader().pause(task);
  }

  Future<void> resumeDownload(String id) async {
    final task = await FileDownloader().taskForId(id);
    if (task is DownloadTask) await FileDownloader().resume(task);
  }

  Future<void> deleteDownload(String id) async {
    LoggerService.downloads.info('[Download: Deleting] [Id: $id]');

    final existing = await _database.getOfflineMedia(id);

    await _database.removeOfflineMedia(id);
    await _deleteLocalImages(id);

    _activeCache.remove(id);
    _emitActive();

    await FileDownloader().cancelTaskWithId(id);
    await FileDownloader().database.deleteRecordWithId(id);

    if (existing != null) {
      final file = File(existing.localPath);
      if (await file.exists()) await file.delete();
    }
  }

  void dispose() {
    _updatesSubscription?.cancel();
    _updatesSubscription = null;
    _activeController.close();
  }

  Future<void> clearAll() async {
    _activeCache.clear();
    _emitActive();

    final items = await _database.getAllOfflineMedia();
    for (final item in items) {
      final file = File(item.localPath);
      if (await file.exists()) await file.delete();
    }

    final records = await FileDownloader().database.allRecords();
    for (final record in records) {
      try {
        final path = await record.task.filePath();
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }

    await _deleteAllLocalImages();

    await _database.clearAllMedia();
    await FileDownloader().database.deleteAllRecords();
    await FileDownloader().cancelAll();
  }

  Future<MediaItem> _fetchFullItem(String itemId) async {
    return _libraryRepository.getItem(itemId);
  }

  Future<String> _downloadImage({
    required String url,
    required String itemId,
    required String suffix,
    int? width,
  }) async {
    if (url.isEmpty) throw Exception('Image URL is empty');
    final client = _jellyfinClient.client;
    if (client == null) throw Exception('No authenticated client');

    final imageDir = await _getImageDirectory();
    const ext = 'jpg';
    final filePath = p.join(imageDir.path, '${itemId}_$suffix.$ext');
    final file = File(filePath);

    if (await file.exists()) return filePath;

    String imageUrl = url;
    if (width != null) {
      final separator = url.contains('?') ? '&' : '?';
      imageUrl = '$url${separator}width=$width&quality=80';
    }

    final response = await client.dio.get(
      imageUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    await file.writeAsBytes(response.data as List<int>);
    return filePath;
  }

  Future<Directory> _getImageDirectory() async {
    final dir = await getApplicationSupportDirectory();
    final imageDir = Directory(p.join(dir.path, 'offline_images'));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir;
  }

  Future<void> _deleteLocalImages(String itemId) async {
    try {
      final imageDir = await _getImageDirectory();
      for (final suffix in ['poster', 'backdrop', 'series_poster']) {
        final file = File(p.join(imageDir.path, '${itemId}_$suffix.jpg'));
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      LoggerService.downloads.warning(
        '[Download: ImageDeleteFailed] [ItemId: $itemId]',
        e,
      );
    }
  }

  Future<void> _deleteAllLocalImages() async {
    try {
      final imageDir = await _getImageDirectory();
      if (await imageDir.exists()) {
        await imageDir.delete(recursive: true);
      }
    } catch (e) {
      LoggerService.downloads.warning('[Download: AllImageDeleteFailed]', e);
    }
  }
}
