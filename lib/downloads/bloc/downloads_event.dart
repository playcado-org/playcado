part of 'downloads_bloc.dart';

abstract class DownloadsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class DownloadsDeleteRequested extends DownloadsEvent {
  DownloadsDeleteRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class DownloadsInitialized extends DownloadsEvent {}

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

class DownloadsStartRequested extends DownloadsEvent {
  DownloadsStartRequested(this.item);
  final DownloadItem item;
  @override
  List<Object?> get props => [item];
}

class DownloadsRequested extends DownloadsEvent {
  DownloadsRequested({
    required this.item,
  });
  final MediaItem item;

  @override
  List<Object?> get props => [item];
}

class DownloadsUpdated extends DownloadsEvent {
  DownloadsUpdated(this.items);
  final List<DownloadItem> items;
  @override
  List<Object?> get props => [items];
}
