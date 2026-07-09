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
  static const String _recentSearchesKey = 'recent_searches';
  static const String _themeColorKey = 'theme_color';

  bool readIsFirstRun() {
    return _prefs.getBool(_firstRunKey) ?? true;
  }

  List<String> readRecentSearches({required String userId}) {
    return _prefs.getStringList('${_recentSearchesKey}_$userId') ?? [];
  }

  Color? readThemeColor() {
    final colorInt = _prefs.getInt(_themeColorKey);
    return colorInt != null ? Color(colorInt) : null;
  }

  Future<void> resetAll() async {
    LoggerService.preferencesService.warning('Resetting all app preferences');
    await _prefs.clear();
  }

  Future<void> writeIsFirstRun() async {
    LoggerService.preferencesService.info('Setting first run as completed');
    await _prefs.setBool(_firstRunKey, false);
  }

  Future<void> writeRecentSearches({
    required List<String> searches,
    required String userId,
  }) async {
    await _prefs.setStringList('${_recentSearchesKey}_$userId', searches);
  }

  Future<void> writeThemeColor(Color color) async {
    await _prefs.setInt(_themeColorKey, color.toARGB32());
  }
}
