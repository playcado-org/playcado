import 'package:equatable/equatable.dart';
import 'package:playcado/media/models/media_item.dart';

enum ActiveDownloadStatus { queued, downloading, paused, error }

class ActiveDownload extends Equatable {
  const ActiveDownload({
    required this.media,
    this.status = ActiveDownloadStatus.queued,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.networkSpeed,
    this.errorReason,
  });

  final MediaItem media;
  final ActiveDownloadStatus status;
  final double progress;
  final int receivedBytes;
  final int totalBytes;
  final double? networkSpeed;
  final String? errorReason;

  String get id => media.id;

  ActiveDownload copyWith({
    ActiveDownloadStatus? status,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    double? networkSpeed,
    String? errorReason,
  }) {
    return ActiveDownload(
      media: media,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      networkSpeed: networkSpeed ?? this.networkSpeed,
      errorReason: errorReason ?? this.errorReason,
    );
  }

  @override
  List<Object?> get props => [
    media,
    status,
    progress,
    receivedBytes,
    totalBytes,
    networkSpeed,
    errorReason,
  ];
}
