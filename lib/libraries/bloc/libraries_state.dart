part of 'libraries_bloc.dart';

class LibrariesState extends Equatable {
  const LibrariesState({this.libraries = const StatusInitial()});
  final StatusWrapper<List<MediaItem>> libraries;

  LibrariesState copyWith({StatusWrapper<List<MediaItem>>? libraries}) {
    return LibrariesState(libraries: libraries ?? this.libraries);
  }

  @override
  List<Object> get props => [libraries];
}
