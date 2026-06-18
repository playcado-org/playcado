part of 'player_bloc.dart';

enum PlayerStatus { initial, loading, playing, paused, stopped, error }

class PlayerState extends Equatable {
  const PlayerState({
    this.status = PlayerStatus.initial,
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

  final PlayerStatus status;
  final MediaItem? mediaItem;
  final String? localPath;
  final bool isLocalMedia;
  final bool isCasting;
  final Duration position;
  final Duration duration;
  final bool isBuffering;
  final bool showSkipIntro;
  final Object? nativeViewAttachment;

  PlayerState copyWith({
    PlayerStatus? status,
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
    return PlayerState(
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
      status == PlayerStatus.playing ||
      status == PlayerStatus.paused ||
      status == PlayerStatus.loading;

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

  bool isPositionOnlyChange(PlayerState other) {
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
