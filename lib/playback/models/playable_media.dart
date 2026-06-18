import 'package:equatable/equatable.dart';

class PlayableMedia extends Equatable {
  const PlayableMedia({
    required this.id,
    required this.title,
    this.subtitle,
    required this.streamUrl,
    required this.posterUrl,
    this.httpHeaders,
    this.startPosition = Duration.zero,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String streamUrl;
  final String posterUrl;
  final Map<String, String>? httpHeaders;
  final Duration startPosition;

  PlayableMedia copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? streamUrl,
    String? posterUrl,
    Map<String, String>? httpHeaders,
    Duration? startPosition,
  }) {
    return PlayableMedia(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      streamUrl: streamUrl ?? this.streamUrl,
      posterUrl: posterUrl ?? this.posterUrl,
      httpHeaders: httpHeaders ?? this.httpHeaders,
      startPosition: startPosition ?? this.startPosition,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    streamUrl,
    posterUrl,
    httpHeaders,
    startPosition,
  ];
}
