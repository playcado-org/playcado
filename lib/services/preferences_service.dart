import 'dart:ui';

import 'package:playcado/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService._(this._prefs);
  final SharedPreferences _prefs;

  static Future<PreferencesService> create() async {
    return PreferencesService._(await SharedPreferences.getInstance());
  }

  static const String _firstRunKey = 'is_first_run';
  static const String _themeColorKey = 'theme_color';
  static const String _recentSearchesKey = 'recent_searches';

  bool isFirstRun() {
    return _prefs.getBool(_firstRunKey) ?? true;
  }

  Color? getThemeColor() {
    final colorInt = _prefs.getInt(_themeColorKey);
    return colorInt != null ? Color(colorInt) : null;
  }

  List<String> getRecentSearches() {
    return _prefs.getStringList(_recentSearchesKey) ?? [];
  }

  Future<void> setFirstRunCompleted() async {
    LoggerService.preferencesService.info('Setting first run as completed');
    await _prefs.setBool(_firstRunKey, false);
  }

  Future<void> saveThemeColor(Color color) async {
    await _prefs.setInt(_themeColorKey, color.toARGB32());
  }

  Future<void> saveRecentSearches(List<String> searches) async {
    await _prefs.setStringList(_recentSearchesKey, searches);
  }

  Future<void> resetAll() async {
    LoggerService.preferencesService.warning('Resetting all app preferences');
    await _prefs.clear();
  }
}
