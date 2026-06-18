import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playcado/core/extensions.dart';
import 'package:playcado/core/status_wrapper.dart';
import 'package:playcado/paginated_media_list/widgets/media_poster.dart';
import 'package:playcado/search/bloc/search_bloc.dart';
import 'package:playcado/search/repositories/search_repository.dart';
import 'package:playcado/widgets/widgets.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SearchBloc(searchRepository: context.read<SearchRepository>()),
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
    return Scaffold(
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
          onChanged: _onSearchChanged,
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
    );
  }
}
