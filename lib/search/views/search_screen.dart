import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/auth/bloc/auth_bloc.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/core/status_wrapper.dart';
import 'package:playcado/paginated_media_list/widgets/media_poster.dart';
import 'package:playcado/search/bloc/search_bloc.dart';
import 'package:playcado/search/repositories/search_repository.dart';
import 'package:playcado/services/preferences_service.dart';
import 'package:playcado/widgets/widgets.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = context.select((AuthBloc bloc) {
      final user = bloc.state.user;
      return user.isSuccess ? user.value!.id : '';
    });
    return BlocProvider(
      create: (context) => SearchBloc(
        preferencesService: context.read<PreferencesService>(),
        searchRepository: context.read<SearchRepository>(),
        userId: userId,
      ),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<SearchBloc>().add(SearchQueryChanged(query));
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          final query = _controller.text;
          if (query.isNotEmpty) {
            context.read<SearchBloc>().add(SearchSaveRequested(query));
          }
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: context.l10n.searchPlaceholder,
              border: InputBorder.none,
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
            ),
            textInputAction: TextInputAction.search,
            onChanged: _onSearchChanged,
            onSubmitted: (value) {
              context.read<SearchBloc>().add(SearchQuerySubmitted(value));
            },
          ),
          actions: [
            IconButton(
              icon: const PlaycadoIcon(PlaycadoIcons.close),
              onPressed: () {
                _controller.clear();
                context.read<SearchBloc>().add(SearchClearRequested());
              },
            ),
          ],
        ),
        body: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            if (state.query.isEmpty && state.recentSearches.isNotEmpty) {
              return _RecentSearches(
                recentSearches: state.recentSearches,
                onTap: (query) {
                  _controller.text = query;
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: query.length),
                  );
                  context.read<SearchBloc>().add(SearchQuerySubmitted(query));
                },
                onRemove: (query) {
                  context.read<SearchBloc>().add(
                    SearchRecentSearchRemoved(query),
                  );
                },
                onClear: () {
                  context.read<SearchBloc>().add(SearchRecentSearchesCleared());
                },
              );
            }

            return switch (state.items) {
              StatusLoading() => const LoadingIndicator(),
              StatusError(:final message) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PlaycadoIcon(
                      PlaycadoIcons.error,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(message),
                  ],
                ),
              ),
              StatusSuccess(:final value) when value.isEmpty => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PlaycadoIcon(
                      PlaycadoIcons.search,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(context.l10n.noResultsFound),
                  ],
                ),
              ),
              StatusSuccess(:final value) => GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: value.length,
                itemBuilder: (context, index) {
                  return MediaPoster(item: value[index]);
                },
              ),
              StatusInitial() => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PlaycadoIcon(
                      PlaycadoIcons.search,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(context.l10n.typeToSearch),
                  ],
                ),
              ),
            };
          },
        ),
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.onTap,
    required this.onRemove,
    required this.onClear,
    required this.recentSearches,
  });

  final VoidCallback onClear;
  final ValueSetter<String> onRemove;
  final ValueSetter<String> onTap;
  final List<String> recentSearches;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Searches',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                onPressed: onClear,
                child: Text(
                  'Clear',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
        for (final query in recentSearches)
          InkWell(
            onTap: () => onTap(query),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ListTile(
                leading: PlaycadoIcon(
                  PlaycadoIcons.search,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(query, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const PlaycadoIcon(PlaycadoIcons.close, size: 18),
                  onPressed: () => onRemove(query),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
