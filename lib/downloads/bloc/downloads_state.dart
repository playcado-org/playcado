part of 'downloads_bloc.dart';

class DownloadsState extends Equatable {
  const DownloadsState({
    this.activeDownloads = const [],
    this.offlineLibrary = const [],
    this.isLoading = true,
  });

  final List<ActiveDownload> activeDownloads;
  final List<DownloadedMediaItem> offlineLibrary;
  final bool isLoading;

  DownloadsState copyWith({
    List<ActiveDownload>? activeDownloads,
    List<DownloadedMediaItem>? offlineLibrary,
    bool? isLoading,
  }) {
    return DownloadsState(
      activeDownloads: activeDownloads ?? this.activeDownloads,
      offlineLibrary: offlineLibrary ?? this.offlineLibrary,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [activeDownloads, offlineLibrary, isLoading];
}
