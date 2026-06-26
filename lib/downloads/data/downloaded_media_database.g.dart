// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'downloaded_media_database.dart';

// ignore_for_file: type=lint
class $DownloadedMediaTableTable extends DownloadedMediaTable
    with TableInfo<$DownloadedMediaTableTable, DownloadedMediaTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadedMediaTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaJsonMeta = const VerificationMeta(
    'mediaJson',
  );
  @override
  late final GeneratedColumn<String> mediaJson = GeneratedColumn<String>(
    'media_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backdropPathMeta = const VerificationMeta(
    'backdropPath',
  );
  @override
  late final GeneratedColumn<String> backdropPath = GeneratedColumn<String>(
    'backdrop_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mediaJson,
    localPath,
    totalBytes,
    downloadedAt,
    posterPath,
    backdropPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloaded_media_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadedMediaTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('media_json')) {
      context.handle(
        _mediaJsonMeta,
        mediaJson.isAcceptableOrUnknown(data['media_json']!, _mediaJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaJsonMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_totalBytesMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('backdrop_path')) {
      context.handle(
        _backdropPathMeta,
        backdropPath.isAcceptableOrUnknown(
          data['backdrop_path']!,
          _backdropPathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadedMediaTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadedMediaTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mediaJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_json'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      )!,
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      backdropPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backdrop_path'],
      ),
    );
  }

  @override
  $DownloadedMediaTableTable createAlias(String alias) {
    return $DownloadedMediaTableTable(attachedDatabase, alias);
  }
}

class DownloadedMediaTableData extends DataClass
    implements Insertable<DownloadedMediaTableData> {
  final String id;
  final String mediaJson;
  final String localPath;
  final int totalBytes;
  final DateTime downloadedAt;
  final String? posterPath;
  final String? backdropPath;
  const DownloadedMediaTableData({
    required this.id,
    required this.mediaJson,
    required this.localPath,
    required this.totalBytes,
    required this.downloadedAt,
    this.posterPath,
    this.backdropPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['media_json'] = Variable<String>(mediaJson);
    map['local_path'] = Variable<String>(localPath);
    map['total_bytes'] = Variable<int>(totalBytes);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    if (!nullToAbsent || backdropPath != null) {
      map['backdrop_path'] = Variable<String>(backdropPath);
    }
    return map;
  }

  DownloadedMediaTableCompanion toCompanion(bool nullToAbsent) {
    return DownloadedMediaTableCompanion(
      id: Value(id),
      mediaJson: Value(mediaJson),
      localPath: Value(localPath),
      totalBytes: Value(totalBytes),
      downloadedAt: Value(downloadedAt),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      backdropPath: backdropPath == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropPath),
    );
  }

  factory DownloadedMediaTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadedMediaTableData(
      id: serializer.fromJson<String>(json['id']),
      mediaJson: serializer.fromJson<String>(json['mediaJson']),
      localPath: serializer.fromJson<String>(json['localPath']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      backdropPath: serializer.fromJson<String?>(json['backdropPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mediaJson': serializer.toJson<String>(mediaJson),
      'localPath': serializer.toJson<String>(localPath),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
      'posterPath': serializer.toJson<String?>(posterPath),
      'backdropPath': serializer.toJson<String?>(backdropPath),
    };
  }

  DownloadedMediaTableData copyWith({
    String? id,
    String? mediaJson,
    String? localPath,
    int? totalBytes,
    DateTime? downloadedAt,
    Value<String?> posterPath = const Value.absent(),
    Value<String?> backdropPath = const Value.absent(),
  }) => DownloadedMediaTableData(
    id: id ?? this.id,
    mediaJson: mediaJson ?? this.mediaJson,
    localPath: localPath ?? this.localPath,
    totalBytes: totalBytes ?? this.totalBytes,
    downloadedAt: downloadedAt ?? this.downloadedAt,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    backdropPath: backdropPath.present ? backdropPath.value : this.backdropPath,
  );
  DownloadedMediaTableData copyWithCompanion(
    DownloadedMediaTableCompanion data,
  ) {
    return DownloadedMediaTableData(
      id: data.id.present ? data.id.value : this.id,
      mediaJson: data.mediaJson.present ? data.mediaJson.value : this.mediaJson,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      backdropPath: data.backdropPath.present
          ? data.backdropPath.value
          : this.backdropPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedMediaTableData(')
          ..write('id: $id, ')
          ..write('mediaJson: $mediaJson, ')
          ..write('localPath: $localPath, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mediaJson,
    localPath,
    totalBytes,
    downloadedAt,
    posterPath,
    backdropPath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadedMediaTableData &&
          other.id == this.id &&
          other.mediaJson == this.mediaJson &&
          other.localPath == this.localPath &&
          other.totalBytes == this.totalBytes &&
          other.downloadedAt == this.downloadedAt &&
          other.posterPath == this.posterPath &&
          other.backdropPath == this.backdropPath);
}

class DownloadedMediaTableCompanion
    extends UpdateCompanion<DownloadedMediaTableData> {
  final Value<String> id;
  final Value<String> mediaJson;
  final Value<String> localPath;
  final Value<int> totalBytes;
  final Value<DateTime> downloadedAt;
  final Value<String?> posterPath;
  final Value<String?> backdropPath;
  final Value<int> rowid;
  const DownloadedMediaTableCompanion({
    this.id = const Value.absent(),
    this.mediaJson = const Value.absent(),
    this.localPath = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadedMediaTableCompanion.insert({
    required String id,
    required String mediaJson,
    required String localPath,
    required int totalBytes,
    required DateTime downloadedAt,
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mediaJson = Value(mediaJson),
       localPath = Value(localPath),
       totalBytes = Value(totalBytes),
       downloadedAt = Value(downloadedAt);
  static Insertable<DownloadedMediaTableData> custom({
    Expression<String>? id,
    Expression<String>? mediaJson,
    Expression<String>? localPath,
    Expression<int>? totalBytes,
    Expression<DateTime>? downloadedAt,
    Expression<String>? posterPath,
    Expression<String>? backdropPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaJson != null) 'media_json': mediaJson,
      if (localPath != null) 'local_path': localPath,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (posterPath != null) 'poster_path': posterPath,
      if (backdropPath != null) 'backdrop_path': backdropPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadedMediaTableCompanion copyWith({
    Value<String>? id,
    Value<String>? mediaJson,
    Value<String>? localPath,
    Value<int>? totalBytes,
    Value<DateTime>? downloadedAt,
    Value<String?>? posterPath,
    Value<String?>? backdropPath,
    Value<int>? rowid,
  }) {
    return DownloadedMediaTableCompanion(
      id: id ?? this.id,
      mediaJson: mediaJson ?? this.mediaJson,
      localPath: localPath ?? this.localPath,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mediaJson.present) {
      map['media_json'] = Variable<String>(mediaJson.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (backdropPath.present) {
      map['backdrop_path'] = Variable<String>(backdropPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedMediaTableCompanion(')
          ..write('id: $id, ')
          ..write('mediaJson: $mediaJson, ')
          ..write('localPath: $localPath, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$DownloadedMediaDatabase extends GeneratedDatabase {
  _$DownloadedMediaDatabase(QueryExecutor e) : super(e);
  $DownloadedMediaDatabaseManager get managers =>
      $DownloadedMediaDatabaseManager(this);
  late final $DownloadedMediaTableTable downloadedMediaTable =
      $DownloadedMediaTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [downloadedMediaTable];
}

typedef $$DownloadedMediaTableTableCreateCompanionBuilder =
    DownloadedMediaTableCompanion Function({
      required String id,
      required String mediaJson,
      required String localPath,
      required int totalBytes,
      required DateTime downloadedAt,
      Value<String?> posterPath,
      Value<String?> backdropPath,
      Value<int> rowid,
    });
typedef $$DownloadedMediaTableTableUpdateCompanionBuilder =
    DownloadedMediaTableCompanion Function({
      Value<String> id,
      Value<String> mediaJson,
      Value<String> localPath,
      Value<int> totalBytes,
      Value<DateTime> downloadedAt,
      Value<String?> posterPath,
      Value<String?> backdropPath,
      Value<int> rowid,
    });

class $$DownloadedMediaTableTableFilterComposer
    extends Composer<_$DownloadedMediaDatabase, $DownloadedMediaTableTable> {
  $$DownloadedMediaTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaJson => $composableBuilder(
    column: $table.mediaJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadedMediaTableTableOrderingComposer
    extends Composer<_$DownloadedMediaDatabase, $DownloadedMediaTableTable> {
  $$DownloadedMediaTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaJson => $composableBuilder(
    column: $table.mediaJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadedMediaTableTableAnnotationComposer
    extends Composer<_$DownloadedMediaDatabase, $DownloadedMediaTableTable> {
  $$DownloadedMediaTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mediaJson =>
      $composableBuilder(column: $table.mediaJson, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => column,
  );
}

class $$DownloadedMediaTableTableTableManager
    extends
        RootTableManager<
          _$DownloadedMediaDatabase,
          $DownloadedMediaTableTable,
          DownloadedMediaTableData,
          $$DownloadedMediaTableTableFilterComposer,
          $$DownloadedMediaTableTableOrderingComposer,
          $$DownloadedMediaTableTableAnnotationComposer,
          $$DownloadedMediaTableTableCreateCompanionBuilder,
          $$DownloadedMediaTableTableUpdateCompanionBuilder,
          (
            DownloadedMediaTableData,
            BaseReferences<
              _$DownloadedMediaDatabase,
              $DownloadedMediaTableTable,
              DownloadedMediaTableData
            >,
          ),
          DownloadedMediaTableData,
          PrefetchHooks Function()
        > {
  $$DownloadedMediaTableTableTableManager(
    _$DownloadedMediaDatabase db,
    $DownloadedMediaTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadedMediaTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadedMediaTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DownloadedMediaTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mediaJson = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<int> totalBytes = const Value.absent(),
                Value<DateTime> downloadedAt = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> backdropPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadedMediaTableCompanion(
                id: id,
                mediaJson: mediaJson,
                localPath: localPath,
                totalBytes: totalBytes,
                downloadedAt: downloadedAt,
                posterPath: posterPath,
                backdropPath: backdropPath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mediaJson,
                required String localPath,
                required int totalBytes,
                required DateTime downloadedAt,
                Value<String?> posterPath = const Value.absent(),
                Value<String?> backdropPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadedMediaTableCompanion.insert(
                id: id,
                mediaJson: mediaJson,
                localPath: localPath,
                totalBytes: totalBytes,
                downloadedAt: downloadedAt,
                posterPath: posterPath,
                backdropPath: backdropPath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadedMediaTableTableProcessedTableManager =
    ProcessedTableManager<
      _$DownloadedMediaDatabase,
      $DownloadedMediaTableTable,
      DownloadedMediaTableData,
      $$DownloadedMediaTableTableFilterComposer,
      $$DownloadedMediaTableTableOrderingComposer,
      $$DownloadedMediaTableTableAnnotationComposer,
      $$DownloadedMediaTableTableCreateCompanionBuilder,
      $$DownloadedMediaTableTableUpdateCompanionBuilder,
      (
        DownloadedMediaTableData,
        BaseReferences<
          _$DownloadedMediaDatabase,
          $DownloadedMediaTableTable,
          DownloadedMediaTableData
        >,
      ),
      DownloadedMediaTableData,
      PrefetchHooks Function()
    >;

class $DownloadedMediaDatabaseManager {
  final _$DownloadedMediaDatabase _db;
  $DownloadedMediaDatabaseManager(this._db);
  $$DownloadedMediaTableTableTableManager get downloadedMediaTable =>
      $$DownloadedMediaTableTableTableManager(_db, _db.downloadedMediaTable);
}
