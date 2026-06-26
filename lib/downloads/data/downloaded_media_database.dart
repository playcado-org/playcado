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
  TextColumn get id => text()();
  TextColumn get mediaJson => text()();
  TextColumn get localPath => text()();
  IntColumn get totalBytes => integer()();
  DateTimeColumn get downloadedAt => dateTime()();
  TextColumn get posterPath => text().nullable()();
  TextColumn get backdropPath => text().nullable()();

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
          downloadedMediaTable.posterPath,
        );
        await migrator.addColumn(
          downloadedMediaTable,
          downloadedMediaTable.backdropPath,
        );
      }
    },
  );

  Stream<List<DownloadedMediaItem>> watchOfflineLibrary() {
    return select(downloadedMediaTable).watch().map((rows) {
      return rows.map((row) {
        return DownloadedMediaItem(
          media: MediaItem.fromJson(jsonDecode(row.mediaJson)),
          localPath: row.localPath,
          totalBytes: row.totalBytes,
          downloadedAt: row.downloadedAt,
          localPosterPath: row.posterPath,
          localBackdropPath: row.backdropPath,
        );
      }).toList();
    });
  }

  Future<void> saveOfflineMedia(DownloadedMediaItem item) {
    return into(downloadedMediaTable).insert(
      DownloadedMediaTableCompanion.insert(
        id: item.id,
        mediaJson: jsonEncode(item.media.toJson()),
        localPath: item.localPath,
        totalBytes: item.totalBytes,
        downloadedAt: item.downloadedAt,
        posterPath: Value(item.localPosterPath),
        backdropPath: Value(item.localBackdropPath),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> removeOfflineMedia(String id) {
    return (delete(downloadedMediaTable)..where((t) => t.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'playcado_offline.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
