import 'package:flutter/services.dart' as services;

class AppFlavor {
  static String? get appFlavor => services.appFlavor;
  static bool get isDev => appFlavor == 'dev';
}
