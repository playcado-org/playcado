import 'package:equatable/equatable.dart';

class TrackInfo extends Equatable {
  const TrackInfo({
    required this.index,
    required this.id,
    this.language,
    this.title,
  });

  final int index;
  final String id;
  final String? language;
  final String? title;

  @override
  List<Object?> get props => [index, id, language, title];
}
