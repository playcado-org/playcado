part of 'theme_bloc.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object> get props => [];
}

class ChangeThemeColor extends ThemeEvent {
  const ChangeThemeColor(this.color);
  final Color color;

  @override
  List<Object> get props => [color];
}
