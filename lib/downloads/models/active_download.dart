import 'package:equatable/equatable.dart';
import 'package:playcado/media/models/media_item.dart';

enum ActiveDownloadStatus { queued, downloading, paused, error }

class ActiveDownload extends Equatable {
  const ActiveDownload({
    required this.media,
    this.errorReason,
    this.networkSpeed,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.status = ActiveDownloadStatus.queued,
    this.totalBytes = 0,
  });

  final String? errorReason;
  final MediaItem media;
  final double? networkSpeed;
  final double progress;
  final int receivedBytes;
  final ActiveDownloadStatus status;
  final int totalBytes;

  String get id => media.id;

  ActiveDownload copyWith({
    String? errorReason,
    double? networkSpeed,
    double? progress,
    int? receivedBytes,
    ActiveDownloadStatus? status,
    int? totalBytes,
  }) {
    return ActiveDownload(
      errorReason: errorReason ?? this.errorReason,
      media: media,
      networkSpeed: networkSpeed ?? this.networkSpeed,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      status: status ?? this.status,
      totalBytes: totalBytes ?? this.totalBytes,
    );
  }

  @override
  List<Object?> get props => [
    errorReason,
    media,
    networkSpeed,
    progress,
    receivedBytes,
    status,
    totalBytes,
  ];
}
