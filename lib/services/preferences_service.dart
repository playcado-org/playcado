import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:playcado/services/logger_service.dart';

class PreferencesService {
  static const String _firstRunFileName = '.onboarding_completed';
  static const String _settingsFileName = 'app_settings.json';

  static const String _recentSearchesKey = 'recentSearches';
  static const String _themeColorKey = 'themeColor';

  Future<File> get _firstRunFile async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_firstRunFileName');
  }

  Future<File> get _settingsFile async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_settingsFileName');
  }

  Future<bool> isFirstRun() async {
    try {
      final file = await _firstRunFile;
      // If the file does NOT exist, it IS the first run.
      return !file.existsSync();
    } on Exception catch (e, s) {
      LoggerService.preferencesService.warning(
        'Failed to check first run status',
        e,
        s,
      );
      return true; // Default to showing onboarding if check fails
    }
  }

  Future<void> setFirstRunCompleted() async {
    LoggerService.preferencesService.info('Setting first run as completed');
    try {
      final file = await _firstRunFile;
      if (!file.existsSync()) {
        await file.create(recursive: true);
      }
    } on Exception catch (e, s) {
      LoggerService.preferencesService.severe(
        'Failed to set first run status',
        e,
        s,
      );
    }
  }

  Future<void> saveThemeColor(Color color) async {
    try {
      final file = await _settingsFile;
      var settings = <String, dynamic>{};

      if (file.existsSync()) {
        try {
          final content = file.readAsStringSync();
          settings = jsonDecode(content) as Map<String, dynamic>;
        } on Exception catch (e) {
          LoggerService.preferencesService.warning(
            'Failed to parse settings file, overwriting',
            e,
          );
        }
      }

      settings[_themeColorKey] = color.toARGB32();
      file.writeAsStringSync(jsonEncode(settings));
    } on Exception catch (e, s) {
      LoggerService.preferencesService.severe(
        'Failed to save theme color',
        e,
        s,
      );
    }
  }

  Future<Color?> getThemeColor() async {
    try {
      final file = await _settingsFile;

      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final settings = jsonDecode(content) as Map<String, dynamic>;
        if (settings.containsKey(_themeColorKey)) {
          return Color(settings[_themeColorKey] as int);
        }
      }
    } on Exception catch (e, s) {
      LoggerService.preferencesService.warning(
        'Failed to load theme color',
        e,
        s,
      );
    }
    return null;
  }

  Future<List<String>> getRecentSearches() async {
    try {
      final file = await _settingsFile;
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final settings = jsonDecode(content) as Map<String, dynamic>;
        if (settings.containsKey(_recentSearchesKey)) {
          return List<String>.from(settings[_recentSearchesKey] as List);
        }
      }
    } on Exception catch (e, s) {
      LoggerService.preferencesService.warning(
        'Failed to load recent searches',
        e,
        s,
      );
    }
    return [];
  }

  Future<void> saveRecentSearches(List<String> searches) async {
    try {
      final file = await _settingsFile;
      var settings = <String, dynamic>{};

      if (file.existsSync()) {
        try {
          final content = file.readAsStringSync();
          settings = jsonDecode(content) as Map<String, dynamic>;
        } on Exception catch (e) {
          LoggerService.preferencesService.warning(
            'Failed to parse settings file, overwriting',
            e,
          );
        }
      }

      settings[_recentSearchesKey] = searches;
      file.writeAsStringSync(jsonEncode(settings));
    } on Exception catch (e, s) {
      LoggerService.preferencesService.severe(
        'Failed to save recent searches',
        e,
        s,
      );
    }
  }

  Future<void> resetAll() async {
    try {
      final firstRunFile = await _firstRunFile;
      if (firstRunFile.existsSync()) {
        firstRunFile.deleteSync();
      }
      final settingsFile = await _settingsFile;
      if (settingsFile.existsSync()) {
        settingsFile.deleteSync();
      }
    } on Exception catch (e, s) {
      LoggerService.preferencesService.warning(
        'Failed to reset app preferences',
        e,
        s,
      );
    }
  }
}
