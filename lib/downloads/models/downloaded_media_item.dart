import 'package:equatable/equatable.dart';
import 'package:playcado/media/models/media_item.dart';

class DownloadedMediaItem extends Equatable {
  const DownloadedMediaItem({
    required this.media,
    required this.localPath,
    required this.totalBytes,
    required this.downloadedAt,
  });

  final MediaItem media;
  final String localPath;
  final int totalBytes;
  final DateTime downloadedAt;

  String get id => media.id;

  @override
  List<Object?> get props => [media, localPath, totalBytes, downloadedAt];
}
