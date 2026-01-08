part of 'video_player_bloc.dart';

enum VideoPlayerStatus { initial, loading, playing, paused, stopped, error }

class VideoPlayerState extends Equatable {
  const VideoPlayerState({
    this.status = VideoPlayerStatus.initial,
    this.mediaItem,
    this.localPath,
    this.isLocalMedia = false,
    this.isCasting = false,
    this.position = Duration.zero,
    this.showSkipIntro = false,
  });
  final VideoPlayerStatus status;
  final MediaItem? mediaItem;
  final String? localPath;
  final bool isLocalMedia;
  final bool isCasting;
  final Duration position;
  final bool showSkipIntro;

  VideoPlayerState copyWith({
    VideoPlayerStatus? status,
    MediaItem? mediaItem,
    String? localPath,
    bool? isLocalMedia,
    bool? isCasting,
    Duration? position,
    bool? showSkipIntro,
  }) {
    return VideoPlayerState(
      status: status ?? this.status,
      mediaItem: mediaItem ?? this.mediaItem,
      localPath: localPath ?? this.localPath,
      isLocalMedia: isLocalMedia ?? this.isLocalMedia,
      isCasting: isCasting ?? this.isCasting,
      position: position ?? this.position,
      showSkipIntro: showSkipIntro ?? this.showSkipIntro,
    );
  }

  bool get isActive =>
      status == VideoPlayerStatus.playing ||
      status == VideoPlayerStatus.paused ||
      status == VideoPlayerStatus.loading;

  bool containsItem(MediaItem displayItem) {
    final item = mediaItem;
    if (!isActive || item == null) return false;

    // 1. Exact ID Match (Primary check for all types)
    if (item.id == displayItem.id) return true;

    // 2. Parent-Child Relationship (Series/Episode)
    if (displayItem.type == MediaItemType.series &&
        item.type == MediaItemType.episode) {
      return item.seriesId == displayItem.id ||
          item.seriesName == displayItem.name;
    }

    return false;
  }

  @override
  List<Object?> get props => [
    status,
    mediaItem,
    localPath,
    isLocalMedia,
    isCasting,
    position,
    showSkipIntro,
  ];

  /// Returns true if the only difference between this state
  /// and [other] is the position.
  bool isPositionOnlyChange(VideoPlayerState other) {
    return status == other.status &&
        mediaItem == other.mediaItem &&
        localPath == other.localPath &&
        isLocalMedia == other.isLocalMedia &&
        isCasting == other.isCasting &&
        showSkipIntro == other.showSkipIntro &&
        position != other.position;
  }
}
