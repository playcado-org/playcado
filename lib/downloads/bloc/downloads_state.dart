part of 'downloads_bloc.dart';

class DownloadsState extends Equatable {
  const DownloadsState({
    this.activeDownloads = const [],
    this.isLoading = true,
    this.offlineLibrary = const [],
  });

  final List<ActiveDownload> activeDownloads;
  final bool isLoading;
  final List<DownloadedMediaItem> offlineLibrary;

  DownloadsState copyWith({
    List<ActiveDownload>? activeDownloads,
    bool? isLoading,
    List<DownloadedMediaItem>? offlineLibrary,
  }) {
    return DownloadsState(
      activeDownloads: activeDownloads ?? this.activeDownloads,
      isLoading: isLoading ?? this.isLoading,
      offlineLibrary: offlineLibrary ?? this.offlineLibrary,
    );
  }

  @override
  List<Object> get props => [activeDownloads, isLoading, offlineLibrary];
}
