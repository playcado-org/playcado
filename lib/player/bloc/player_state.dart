part of 'player_bloc.dart';

enum PlayerStatus { initial, loading, playing, paused, stopped, error }

class PlayerState extends Equatable {
  const PlayerState({
    this.duration = Duration.zero,
    this.isBuffering = false,
    this.isCasting = false,
    this.isLocalMedia = false,
    this.localPath,
    this.mediaItem,
    this.playerView,
    this.position = Duration.zero,
    this.showSkipIntro = false,
    this.status = PlayerStatus.initial,
  });

  final Duration duration;
  final bool isBuffering;
  final bool isCasting;
  final bool isLocalMedia;
  final String? localPath;
  final MediaItem? mediaItem;
  final PlayerView? playerView;
  final Duration position;
  final bool showSkipIntro;
  final PlayerStatus status;

  bool get isActive =>
      status == PlayerStatus.playing ||
      status == PlayerStatus.paused ||
      status == PlayerStatus.loading;

  @override
  List<Object?> get props => [
    duration,
    isBuffering,
    isCasting,
    isLocalMedia,
    localPath,
    mediaItem,
    playerView,
    position,
    showSkipIntro,
    status,
  ];

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

  PlayerState copyWith({
    Duration? duration,
    bool? isBuffering,
    bool? isCasting,
    bool? isLocalMedia,
    String? localPath,
    MediaItem? mediaItem,
    PlayerView? playerView,
    Duration? position,
    bool? showSkipIntro,
    PlayerStatus? status,
  }) {
    return PlayerState(
      duration: duration ?? this.duration,
      isBuffering: isBuffering ?? this.isBuffering,
      isCasting: isCasting ?? this.isCasting,
      isLocalMedia: isLocalMedia ?? this.isLocalMedia,
      localPath: localPath ?? this.localPath,
      mediaItem: mediaItem ?? this.mediaItem,
      playerView: playerView ?? this.playerView,
      position: position ?? this.position,
      showSkipIntro: showSkipIntro ?? this.showSkipIntro,
      status: status ?? this.status,
    );
  }

  bool isPositionOnlyChange(PlayerState other) {
    return status == other.status &&
        mediaItem == other.mediaItem &&
        localPath == other.localPath &&
        isLocalMedia == other.isLocalMedia &&
        isCasting == other.isCasting &&
        showSkipIntro == other.showSkipIntro &&
        duration == other.duration &&
        isBuffering == other.isBuffering &&
        playerView == other.playerView &&
        position != other.position;
  }
}
