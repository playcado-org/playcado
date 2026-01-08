part of 'theme_bloc.dart';

class ThemeState extends Equatable {
  const ThemeState({this.themeColor = AppTheme.avocadoGreen});
  final Color themeColor;

  ThemeState copyWith({Color? themeColor}) {
    return ThemeState(themeColor: themeColor ?? this.themeColor);
  }

  @override
  List<Object> get props => [themeColor];
}
