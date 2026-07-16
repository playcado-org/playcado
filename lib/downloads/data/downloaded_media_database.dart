import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:playcado/downloads/models/downloaded_media_item.dart';
import 'package:playcado/media/models/media_item.dart';

part 'downloaded_media_database.g.dart';

class DownloadedMediaTable extends Table {
  TextColumn get backdropPath => text().nullable()();
  DateTimeColumn get downloadedAt => dateTime()();
  TextColumn get id => text()();
  TextColumn get localPath => text()();
  TextColumn get mediaJson => text()();
  TextColumn get posterPath => text().nullable()();
  IntColumn get totalBytes => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [DownloadedMediaTable])
class DownloadedMediaDatabase extends _$DownloadedMediaDatabase {
  DownloadedMediaDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from == 1) {
        await migrator.addColumn(
          downloadedMediaTable,
          downloadedMediaTable.backdropPath,
        );
        await migrator.addColumn(
          downloadedMediaTable,
          downloadedMediaTable.posterPath,
        );
      }
    },
  );

  Future<void> clearAllMedia() {
    return delete(downloadedMediaTable).go();
  }

  Future<List<DownloadedMediaItem>> getAllOfflineMedia() async {
    final rows = await select(downloadedMediaTable).get();
    return rows.map((row) {
      return DownloadedMediaItem(
        downloadedAt: row.downloadedAt,
        localBackdropPath: row.backdropPath,
        localPath: row.localPath,
        localPosterPath: row.posterPath,
        media: MediaItem.fromJson(jsonDecode(row.mediaJson)),
        totalBytes: row.totalBytes,
      );
    }).toList();
  }

  Future<DownloadedMediaItem?> getOfflineMedia(String id) async {
    final rows = await (select(
      downloadedMediaTable,
    )..where((t) => t.id.equals(id))).get();
    if (rows.isEmpty) return null;
    final row = rows.first;
    return DownloadedMediaItem(
      downloadedAt: row.downloadedAt,
      localBackdropPath: row.backdropPath,
      localPath: row.localPath,
      localPosterPath: row.posterPath,
      media: MediaItem.fromJson(jsonDecode(row.mediaJson)),
      totalBytes: row.totalBytes,
    );
  }

  Future<void> removeOfflineMedia(String id) {
    return (delete(downloadedMediaTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> saveOfflineMedia(DownloadedMediaItem item) {
    return into(downloadedMediaTable).insert(
      DownloadedMediaTableCompanion.insert(
        backdropPath: Value(item.localBackdropPath),
        downloadedAt: item.downloadedAt,
        id: item.id,
        localPath: item.localPath,
        mediaJson: jsonEncode(item.media.toJson()),
        posterPath: Value(item.localPosterPath),
        totalBytes: item.totalBytes,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Stream<List<DownloadedMediaItem>> watchOfflineLibrary() {
    return select(downloadedMediaTable).watch().map((rows) {
      return rows.map((row) {
        return DownloadedMediaItem(
          downloadedAt: row.downloadedAt,
          localBackdropPath: row.backdropPath,
          localPath: row.localPath,
          localPosterPath: row.posterPath,
          media: MediaItem.fromJson(jsonDecode(row.mediaJson)),
          totalBytes: row.totalBytes,
        );
      }).toList();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'playcado_offline.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
