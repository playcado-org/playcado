import 'package:equatable/equatable.dart';
import 'package:playcado/media/models/media_item.dart';

class DownloadedMediaItem extends Equatable {
  const DownloadedMediaItem({
    required this.downloadedAt,
    required this.localPath,
    required this.media,
    required this.totalBytes,
    this.localBackdropPath,
    this.localPosterPath,
  });

  final DateTime downloadedAt;
  final String? localBackdropPath;
  final String localPath;
  final String? localPosterPath;
  final MediaItem media;
  final int totalBytes;

  String get id => media.id;

  @override
  List<Object?> get props => [
    downloadedAt,
    localBackdropPath,
    localPath,
    localPosterPath,
    media,
    totalBytes,
  ];
}
