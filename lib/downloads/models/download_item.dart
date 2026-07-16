import 'package:equatable/equatable.dart';
import 'package:playcado/media/models/media_item.dart';

enum DownloadStatus { queued, downloading, paused, completed, error }

class DownloadItem extends Equatable {
  // For calculating time deltas

  const DownloadItem({
    required this.downloadUrl,
    required this.id,
    required this.localPath,
    required this.name,
    this.imageUrl,
    this.indexNumber,
    this.lastUpdateTimeMs,
    this.networkSpeed,
    this.overview,
    this.parentIndexNumber,
    this.productionYear,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.seriesName,
    this.status = DownloadStatus.queued,
    this.totalBytes = 0,
    this.type,
  });

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      downloadUrl: json['downloadUrl'] as String,
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String?,
      indexNumber: json['indexNumber'] as int?,
      lastUpdateTimeMs: json['lastUpdateTimeMs'] as int?,
      localPath: json['localPath'] as String,
      name: json['name'] as String,
      networkSpeed: (json['networkSpeed'] as num?)?.toDouble(),
      overview: json['overview'] as String?,
      parentIndexNumber: json['parentIndexNumber'] as int?,
      productionYear: json['productionYear'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      receivedBytes: (json['receivedBytes'] as int?) ?? 0,
      seriesName: json['seriesName'] as String?,
      status: DownloadStatus.values[(json['status'] as int?) ?? 0],
      totalBytes: (json['totalBytes'] as int?) ?? 0,
      type: json['type'] != null
          ? MediaItemType.fromString(json['type'] as String)
          : null,
    );
  }
  final String downloadUrl;
  final String id;
  final String? imageUrl;
  final int? indexNumber;
  final int? lastUpdateTimeMs;
  final String localPath;
  final String name;
  final double? networkSpeed;
  final String? overview;
  final int? parentIndexNumber;
  final String? productionYear;
  final double progress; // 0.0 to 1.0
  final int receivedBytes;
  final String? seriesName;
  final DownloadStatus status;
  final int totalBytes;
  final MediaItemType? type;

  DownloadItem copyWith({
    String? downloadUrl,
    String? imageUrl,
    int? indexNumber,
    int? lastUpdateTimeMs,
    String? localPath,
    String? name,
    double? networkSpeed,
    String? overview,
    int? parentIndexNumber,
    String? productionYear,
    double? progress,
    int? receivedBytes,
    String? seriesName,
    DownloadStatus? status,
    int? totalBytes,
    MediaItemType? type,
  }) {
    return DownloadItem(
      downloadUrl: downloadUrl ?? this.downloadUrl,
      id: id,
      imageUrl: imageUrl ?? this.imageUrl,
      indexNumber: indexNumber ?? this.indexNumber,
      lastUpdateTimeMs: lastUpdateTimeMs ?? this.lastUpdateTimeMs,
      localPath: localPath ?? this.localPath,
      name: name ?? this.name,
      networkSpeed: networkSpeed ?? this.networkSpeed,
      overview: overview ?? this.overview,
      parentIndexNumber: parentIndexNumber ?? this.parentIndexNumber,
      productionYear: productionYear ?? this.productionYear,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      seriesName: seriesName ?? this.seriesName,
      status: status ?? this.status,
      totalBytes: totalBytes ?? this.totalBytes,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'downloadUrl': downloadUrl,
      'id': id,
      'imageUrl': imageUrl,
      'indexNumber': indexNumber,
      'lastUpdateTimeMs': lastUpdateTimeMs,
      'localPath': localPath,
      'name': name,
      'networkSpeed': networkSpeed,
      'overview': overview,
      'parentIndexNumber': parentIndexNumber,
      'productionYear': productionYear,
      'progress': progress,
      'receivedBytes': receivedBytes,
      'seriesName': seriesName,
      'status': status.index,
      'totalBytes': totalBytes,
      'type': type?.name,
    };
  }

  @override
  String toString() {
    final pct = (progress * 100).toStringAsFixed(1);
    return 'DownloadItem(name: "$name", status: $status, progress: $pct%)';
  }

  @override
  List<Object?> get props => [
    downloadUrl,
    id,
    imageUrl,
    indexNumber,
    lastUpdateTimeMs,
    localPath,
    name,
    networkSpeed,
    overview,
    parentIndexNumber,
    productionYear,
    progress,
    receivedBytes,
    seriesName,
    status,
    totalBytes,
    type,
  ];
}
