part of 'downloads_bloc.dart';

class DownloadsState extends Equatable {
  const DownloadsState({
    this.activeDownloads = const [],
    this.offlineLibrary = const [],
  });

  final List<ActiveDownload> activeDownloads;
  final List<DownloadedMediaItem> offlineLibrary;

  DownloadsState copyWith({
    List<ActiveDownload>? activeDownloads,
    List<DownloadedMediaItem>? offlineLibrary,
  }) {
    return DownloadsState(
      activeDownloads: activeDownloads ?? this.activeDownloads,
      offlineLibrary: offlineLibrary ?? this.offlineLibrary,
    );
  }

  @override
  List<Object> get props => [activeDownloads, offlineLibrary];
}
