import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:playcado/app_router/main_navigation_shell.dart';
import 'package:playcado/auth/bloc/auth_bloc.dart';

import 'package:playcado/devtools/views/dev_tools_screen.dart';
import 'package:playcado/downloads/models/downloaded_media_item.dart';
import 'package:playcado/downloads/views/downloads_screen.dart';
import 'package:playcado/downloads/views/offline_downloads_screen.dart';
import 'package:playcado/downloads/views/offline_media_detail_page.dart';
import 'package:playcado/home/views/home_screen.dart';
import 'package:playcado/libraries/views/library_browse_screen.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/media_details/views/media_details_page.dart';
import 'package:playcado/movies/views/movies_screen.dart';
import 'package:playcado/onboarding/bloc/onboarding_cubit.dart';
import 'package:playcado/onboarding/views/onboarding_screen.dart';
import 'package:playcado/search/views/search_screen.dart';
import 'package:playcado/server_management/views/server_management_screen.dart';
import 'package:playcado/settings/views/settings_screen.dart';
import 'package:playcado/tv/views/tv_shows_screen.dart';
import 'package:playcado/player/views/fullscreen_player_screen.dart';

class AppRouter {
  AppRouter({required this.authBloc, required this.onboardingCubit});
  final AuthBloc authBloc;
  final OnboardingCubit onboardingCubit;

  final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static const basePath = '/';
  static const serverManagementPath = '/server_management';
  static const onboardingPath = '/onboarding';
  static const moviesPath = '/movies';
  static const tvPath = '/tv';
  static const downloadsPath = '/downloads';
  static const devtoolsPath = '/devtools';
  static const detailsPath = '/details';
  static const settingsPath = '/settings';
  static const videoPlayerPath = '/player';
  static const searchPath = '/search';
  static const libraryPath = '/library';
  static const offlineDownloadsPath = '/offline-downloads';
  static const offlineMediaDetailPath = '/offline-media';

  late final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: basePath,
    refreshListenable: Listenable.merge([
      _GoRouterRefreshStream(authBloc.stream),
      _GoRouterRefreshStream(onboardingCubit.stream),
    ]),
    debugLogDiagnostics: kDebugMode,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: moviesPath,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MoviesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: tvPath,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: TvShowsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: basePath,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: downloadsPath,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: ValueKey(state.extra),
                  child: const DownloadsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: searchPath,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SearchScreen()),
      ),
      GoRoute(
        path: detailsPath,
        builder: (context, state) {
          final extra = state.extra! as Map<String, dynamic>;
          final item = extra['item'] as MediaItem;
          final heroTag = extra['heroTag'] as String;
          return MediaDetailsPage(item: item, heroTag: heroTag);
        },
      ),
      GoRoute(
        path: offlineMediaDetailPath,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final item = state.extra! as DownloadedMediaItem;
          return NoTransitionPage(
            key: state.pageKey,
            child: OfflineMediaDetailPage(item: item),
          );
        },
      ),
      GoRoute(
        path: offlineDownloadsPath,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: OfflineDownloadsScreen()),
      ),
      GoRoute(
        path: serverManagementPath,
        builder: (context, state) => const ServerManagementScreen(),
      ),
      GoRoute(
        path: onboardingPath,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: settingsPath,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SettingsScreen()),
      ),
      if (kDebugMode)
        GoRoute(
          path: devtoolsPath,
          builder: (context, state) => const DevToolsScreen(),
        ),
      GoRoute(
        path: videoPlayerPath,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const FullscreenPlayerScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          );
        },
      ),
      GoRoute(
        path: libraryPath,
        builder: (context, state) {
          final item = state.extra! as MediaItem;
          return LibraryBrowseScreen(library: item);
        },
      ),
    ],
    redirect: (context, state) {
      final isFirstRun = onboardingCubit.state;
      final authState = authBloc.state;
      final isLoggedIn = authState.user.isSuccess;

      final isGoingToOnboarding = state.matchedLocation == onboardingPath;
      final isGoingToLogin = state.matchedLocation == serverManagementPath;
      final isGoingToOfflineDownloads =
          state.matchedLocation == offlineDownloadsPath;
      final isGoingToOfflineMedia =
          state.matchedLocation == offlineMediaDetailPath;
      final isGoingToVideoPlayer = state.matchedLocation == videoPlayerPath;

      // 1. Priority: Onboarding
      if (isFirstRun) {
        return isGoingToOnboarding ? null : onboardingPath;
      }

      // 2. Priority: Auth
      if (!isLoggedIn && !authState.isDemoMode) {
        // If coming from Onboarding (just finished), fall through
        if (isGoingToLogin ||
            isGoingToOfflineDownloads ||
            isGoingToOfflineMedia ||
            isGoingToVideoPlayer)
          return null;
        return serverManagementPath;
      }

      // 3. Priority: Authenticated User Navigation
      if (isLoggedIn && (isGoingToLogin || isGoingToOnboarding)) {
        return basePath;
      }

      return null;
    },
  );
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
