part of 'downloads_bloc.dart';

abstract class DownloadsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class DownloadsRequested extends DownloadsEvent {
  DownloadsRequested({required this.item});

  final MediaItem item;

  @override
  List<Object?> get props => [item];
}

class DownloadsDeleteRequested extends DownloadsEvent {
  DownloadsDeleteRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class DownloadsPauseRequested extends DownloadsEvent {
  DownloadsPauseRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class DownloadsResumeRequested extends DownloadsEvent {
  DownloadsResumeRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class _ActiveUpdated extends DownloadsEvent {
  _ActiveUpdated(this.items);

  final List<ActiveDownload> items;

  @override
  List<Object?> get props => [items];
}

class _LibraryUpdated extends DownloadsEvent {
  _LibraryUpdated(this.items);

  final List<DownloadedMediaItem> items;

  @override
  List<Object?> get props => [items];
}
