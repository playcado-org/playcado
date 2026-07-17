import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/media/models/media_item.dart';
import 'package:playcado/paginated_media_list/widgets/media_poster.dart';
import 'package:playcado/player/bloc/player_bloc.dart';
import 'package:playcado/widgets/widgets.dart';

class PaginatedMediaGrid extends StatefulWidget {
  const PaginatedMediaGrid({
    required this.title,
    required this.header,
    required this.items,
    required this.isLoading,
    required this.isError,
    required this.hasReachedMax,
    required this.sortBy,
    required this.sortOrder,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onRetry,
    required this.onSortChanged,
    super.key,
    this.dateSortLabel = 'Release Date',
  });
  final String title;
  final Widget header;
  final List<MediaItem>? items;
  final bool isLoading;
  final bool isError;
  final bool hasReachedMax;
  final String sortBy;
  final String sortOrder;
  final VoidCallback onLoadMore;
  final RefreshCallback onRefresh;
  final VoidCallback onRetry;
  final void Function(String sortBy, String sortOrder) onSortChanged;
  final String dateSortLabel;

  @override
  State<PaginatedMediaGrid> createState() => _PaginatedMediaGridState();
}

class _PaginatedMediaGridState extends State<PaginatedMediaGrid> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && !widget.isLoading && !widget.hasReachedMax) {
      widget.onLoadMore();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final posterCacheWidth = (160 * devicePixelRatio).round();
    final posterCacheHeight = (240 * devicePixelRatio).round();

    if (widget.isLoading && widget.items == null) {
      return CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                childAspectRatio: 0.50,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    const MediaPoster(isLoading: true, width: 160),
                childCount: 12,
              ),
            ),
          ),
        ],
      );
    } else if (widget.isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PlaycadoIcon(
              PlaycadoIcons.error,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(context.l10n.unableToLoadContent),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: widget.onRetry,
              icon: const PlaycadoIcon(PlaycadoIcons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }

    final items = widget.items ?? [];

    final playerActive = context.select<PlayerBloc, bool>(
      (bloc) => bloc.state.isActive,
    );
    final bottomPadding =
        MediaQuery.paddingOf(context).bottom + 10 + (playerActive ? 70 : 0);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        scrollCacheExtent: const ScrollCacheExtent.pixels(300),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          if (items.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  context.l10n.noItemsFound(widget.title.toLowerCase()),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160,
                  childAspectRatio: 0.50,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = index < items.length ? items[index] : null;
                    return MediaPoster(
                      item: item,
                      isLoading: item == null,
                      width: 160,
                      customCacheWidth: posterCacheWidth,
                      customCacheHeight: posterCacheHeight,
                    );
                  },
                  childCount: widget.hasReachedMax
                      ? items.length
                      : items.length + 1,
                  addAutomaticKeepAlives: false,
                ),
              ),
            ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      title: widget.header,
      floating: true,
      pinned: true,
      snap: true,
      centerTitle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      actions: [
        IconButton(
          icon: const PlaycadoIcon(PlaycadoIcons.sort),
          tooltip: context.l10n.sortTitle(widget.title),
          onPressed: () {
            unawaited(
              showModalBottomSheet<void>(
                context: context,
                useRootNavigator: true,
                showDragHandle: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (sheetContext) => _SortSheet(
                  title: context.l10n.sortTitle(widget.title),
                  dateLabel: widget.dateSortLabel,
                  currentSortBy: widget.sortBy,
                  currentSortOrder: widget.sortOrder,
                  onSortSelected: (newSortBy, newSortOrder) {
                    context.pop(sheetContext);
                    widget.onSortChanged(newSortBy, newSortOrder);
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({
    required this.title,
    required this.dateLabel,
    required this.currentSortBy,
    required this.currentSortOrder,
    required this.onSortSelected,
  });
  final String title;
  final String dateLabel;
  final String currentSortBy;
  final String currentSortOrder;
  final void Function(String, String) onSortSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSortOption(
            context,
            title: context.l10n.alphabetical,
            subtitle: context.l10n.aToZ,
            icon: PlaycadoIcons.sort,
            valueSortBy: 'SortName',
            valueSortOrder: 'Ascending',
          ),
          _buildSortOption(
            context,
            title: dateLabel,
            subtitle: context.l10n.newestFirst,
            icon: PlaycadoIcons.calendar,
            valueSortBy: 'PremiereDate',
            valueSortOrder: 'Descending',
          ),
          _buildSortOption(
            context,
            title: context.l10n.dateAdded,
            subtitle: context.l10n.newestFirst,
            icon: PlaycadoIcons.clock,
            valueSortBy: 'DateCreated',
            valueSortOrder: 'Descending',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required PlaycadoIcons icon,
    required String valueSortBy,
    required String valueSortOrder,
  }) {
    final isSelected =
        currentSortBy == valueSortBy && currentSortOrder == valueSortOrder;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => onSortSelected(valueSortBy, valueSortOrder),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.secondaryContainer.withValues(alpha: 0.5)
              : null,
        ),
        child: Row(
          children: [
            PlaycadoIcon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              PlaycadoIcon(PlaycadoIcons.check, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
