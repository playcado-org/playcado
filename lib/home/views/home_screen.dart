import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:playcado/app_router/app_router.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/core/status_wrapper.dart';
import 'package:playcado/home/bloc/home_bloc.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/media/repos/library_repository.dart';
import 'package:playcado/paginated_media_list/widgets/media_poster.dart';
import 'package:playcado/services/logger_service.dart';
import 'package:playcado/video_player/bloc/video_player_bloc.dart';
import 'package:playcado/widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    LoggerService.home.info('Building HomeScreen');
    return BlocProvider(
      create: (context) =>
          HomeBloc(libraryRepository: context.read<LibraryRepository>())
            ..add(LoadHomeContent()),
      child: const Scaffold(extendBodyBehindAppBar: true, body: _HomeContent()),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  Future<void> _refresh(BuildContext context) async {
    context.read<HomeBloc>().add(LoadHomeContent());
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final playerActive = context.select<VideoPlayerBloc, bool>(
      (bloc) => bloc.state.isActive,
    );
    final bottomPadding =
        MediaQuery.paddingOf(context).bottom + 10 + (playerActive ? 70 : 0);

    // Calculate dimensions to match PaginatedMediaGrid
    // (maxCrossAxisExtent: 160, ratio: 0.5)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final availableWidth = screenWidth - 32; // 16px horizontal padding
    final crossAxisCount = (availableWidth / 160).ceil();
    final itemWidth =
        (availableWidth - (crossAxisCount - 1) * 12) / crossAxisCount;
    final itemHeight = itemWidth / 0.5;

    // Landscape dimensions for Up Next (slightly reduced width)
    final nextUpWidth = screenWidth * 0.65;
    final nextUpHeight = (nextUpWidth / 1.77) + 56;

    // Select only the global loading state for the initial data fetch
    final isInitialLoading = context.select<HomeBloc, bool>(
      (bloc) =>
          bloc.state.continueWatching.isLoading &&
          bloc.state.nextUp.isLoading &&
          bloc.state.latestMovies.value == null,
    );

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: CustomScrollView(
        cacheExtent: 1000,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _HomeAppBar(),
          if (isInitialLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    _MediaCarousel(
                      title: context.l10n.upNext,
                      items: null,
                      isLoading: true,
                      category: 'shimmer',
                      itemWidth: nextUpWidth,
                      itemHeight: nextUpHeight,
                      isLandscape: true,
                    ),
                    _MediaCarousel(
                      title: context.l10n.continueWatching,
                      items: null,
                      isLoading: true,
                      category: 'shimmer',
                      itemWidth: itemWidth,
                      itemHeight: itemHeight,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NextUpSection(width: nextUpWidth, height: nextUpHeight),
                    _ContinueWatchingSection(
                      width: itemWidth,
                      height: itemHeight,
                    ),
                    _LatestMoviesSection(width: itemWidth, height: itemHeight),
                    _LatestTvSection(width: itemWidth, height: itemHeight),
                    SizedBox(height: bottomPadding),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: IconTitle(title: context.l10n.playcado),
      centerTitle: true,
      floating: true,
      pinned: true,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0.7),
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      actions: [
        IconButton(
          icon: const PlaycadoIcon(PlaycadoIcons.search),
          onPressed: () => context.push(AppRouter.searchPath),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _ContinueWatchingSection extends StatelessWidget {
  const _ContinueWatchingSection({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final status = context.select<HomeBloc, StatusWrapper<List<MediaItem>>>(
      (bloc) => bloc.state.continueWatching,
    );

    return _MediaCarousel(
      title: context.l10n.continueWatching,
      items: status.value,
      isLoading: status.isLoading,
      isError: status.isError,
      onRetry: () => context.read<HomeBloc>().add(LoadHomeContent()),
      category: 'continue',
      itemWidth: width,
      itemHeight: height,
    );
  }
}

class _NextUpSection extends StatelessWidget {
  const _NextUpSection({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final status = context.select<HomeBloc, StatusWrapper<List<MediaItem>>>(
      (bloc) => bloc.state.nextUp,
    );

    return _MediaCarousel(
      title: context.l10n.upNext,
      items: status.value,
      isLoading: status.isLoading,
      isError: status.isError,
      onRetry: () => context.read<HomeBloc>().add(LoadHomeContent()),
      category: 'upnext',
      itemWidth: width,
      itemHeight: height,
      isLandscape: true,
    );
  }
}

class _LatestMoviesSection extends StatelessWidget {
  const _LatestMoviesSection({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final status = context.select<HomeBloc, StatusWrapper<List<MediaItem>>>(
      (bloc) => bloc.state.latestMovies,
    );

    return _MediaCarousel(
      title: context.l10n.recentlyAddedMovies,
      items: status.value,
      isLoading: status.isLoading,
      isError: status.isError,
      onRetry: () => context.read<HomeBloc>().add(LoadHomeContent()),
      category: 'latest_movies',
      onSeeAll: () => context.go(AppRouter.moviesPath),
      itemWidth: width,
      itemHeight: height,
    );
  }
}

class _LatestTvSection extends StatelessWidget {
  const _LatestTvSection({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final status = context.select<HomeBloc, StatusWrapper<List<MediaItem>>>(
      (bloc) => bloc.state.latestTv,
    );

    return _MediaCarousel(
      title: context.l10n.recentlyAddedTv,
      items: status.value,
      isLoading: status.isLoading,
      isError: status.isError,
      onRetry: () => context.read<HomeBloc>().add(LoadHomeContent()),
      category: 'latest_tv',
      onSeeAll: () => context.go(AppRouter.tvPath),
      itemWidth: width,
      itemHeight: height,
    );
  }
}

class _MediaCarousel extends StatelessWidget {
  const _MediaCarousel({
    required this.title,
    required this.items,
    required this.category,
    required this.itemWidth,
    required this.itemHeight,
    this.isLoading = false,
    this.isError = false,
    this.onSeeAll,
    this.onRetry,
    this.isLandscape = false,
  });
  final String title;
  final List<MediaItem>? items;
  final bool isLoading;
  final bool isError;
  final VoidCallback? onSeeAll;
  final VoidCallback? onRetry;
  final String category;
  final double itemWidth;
  final double itemHeight;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && !isError && (items?.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: onSeeAll != null,
          label: onSeeAll != null ? '${context.l10n.seeAll} $title' : title,
          child: InkWell(
            onTap: onSeeAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Text(
                    title,
                    style:
                        Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  if (onSeeAll != null)
                    const PlaycadoIcon(PlaycadoIcons.arrowRight, size: 14),
                ],
              ),
            ),
          ),
        ),
        if (isError)
          SizedBox(
            height: itemHeight,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.unableToLoadContent,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const PlaycadoIcon(PlaycadoIcons.refresh, size: 14),
                    label: Text(context.l10n.retry),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: itemHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemExtent: itemWidth + 12,
              itemCount: isLoading ? 5 : items?.length ?? 0,
              itemBuilder: (context, index) {
                final item = items?[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: MediaPoster(
                    item: item,
                    heroTag: '${category}_${item?.id}_$index',
                    isLandscape: isLandscape,
                    isLoading: isLoading || item == null,
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
