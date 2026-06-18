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
    this.duration = Duration.zero,
    this.isBuffering = false,
    this.showSkipIntro = false,
    this.nativeViewAttachment,
  });

  final VideoPlayerStatus status;
  final MediaItem? mediaItem;
  final String? localPath;
  final bool isLocalMedia;
  final bool isCasting;
  final Duration position;
  final Duration duration;
  final bool isBuffering;
  final bool showSkipIntro;
  final Object? nativeViewAttachment;

  VideoPlayerState copyWith({
    VideoPlayerStatus? status,
    MediaItem? mediaItem,
    String? localPath,
    bool? isLocalMedia,
    bool? isCasting,
    Duration? position,
    Duration? duration,
    bool? isBuffering,
    bool? showSkipIntro,
    Object? nativeViewAttachment,
  }) {
    return VideoPlayerState(
      status: status ?? this.status,
      mediaItem: mediaItem ?? this.mediaItem,
      localPath: localPath ?? this.localPath,
      isLocalMedia: isLocalMedia ?? this.isLocalMedia,
      isCasting: isCasting ?? this.isCasting,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isBuffering: isBuffering ?? this.isBuffering,
      showSkipIntro: showSkipIntro ?? this.showSkipIntro,
      nativeViewAttachment: nativeViewAttachment ?? this.nativeViewAttachment,
    );
  }

  bool get isActive =>
      status == VideoPlayerStatus.playing ||
      status == VideoPlayerStatus.paused ||
      status == VideoPlayerStatus.loading;

  bool containsItem(MediaItem displayItem) {
    final item = mediaItem;
    if (!isActive || item == null) return false;

    if (item.id == displayItem.id) return true;

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
    duration,
    isBuffering,
    showSkipIntro,
    nativeViewAttachment,
  ];

  bool isPositionOnlyChange(VideoPlayerState other) {
    return status == other.status &&
        mediaItem == other.mediaItem &&
        localPath == other.localPath &&
        isLocalMedia == other.isLocalMedia &&
        isCasting == other.isCasting &&
        showSkipIntro == other.showSkipIntro &&
        duration == other.duration &&
        isBuffering == other.isBuffering &&
        nativeViewAttachment == other.nativeViewAttachment &&
        position != other.position;
  }
}
