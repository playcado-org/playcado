import 'package:flutter/material.dart';
import 'package:playcado/services/logger_service.dart';

class AppRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    LoggerService.ui.info(
      '[Navigation: Push] [Route: ${route.settings.name ?? route.toString()}]',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    LoggerService.ui.info(
      '[Navigation: Pop] [Route: ${route.settings.name ?? route.toString()}]',
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    LoggerService.ui.info(
      '[Navigation: Replace] [Route: ${newRoute?.settings.name ?? newRoute?.toString()}]',
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    LoggerService.ui.info(
      '[Navigation: Remove] [Route: ${route.settings.name ?? route.toString()}]',
    );
  }
}
