# Agent instructions

## Formatting

Always run `dart format lib/` after making any edits to Dart files.

## Alphabetize

Apply alphabetical ordering throughout Dart/Flutter source files:

1. **Imports** — Sort alphabetically by package path within each import group (dart:, package:, relative).
2. **Classes** — Sort members alphabetically: fields first, then getters/setters, then methods.
3. **Constructor parameters** — Required parameters first (alpha), then not-required parameters (alpha).
4. **Initializer list** — Sort alphabetically.
5. **Event registrations** (`on<...>`) — Sort alphabetically by event name.
6. **Switch cases / if-else chains** — Sort alphabetically where order is not semantically meaningful.
7. **Method parameters** — Required parameters first (alpha), then not-required parameters (alpha).
8. **Public before private** — Within each group, public members precede private ones, then alpha-sorted.

```dart
// Event registrations — alpha by event name
on<PlayerPauseRequested>(_onPauseRequested);
on<PlayerPlayRequested>(_onPlayRequested);
on<PlayerResumeRequested>(_onResumeRequested);
on<PlayerSeekRequested>(_onSeekRequested);
on<PlayerStopRequested>(_onStopRequested);
on<ServiceStateUpdated>(_onInternalServiceStateUpdated);
```

```dart
// Constructor params — required first (alpha), then not-required (alpha)
PlayerBloc({
  required CastDeviceManager castDeviceManager,
  required CastPlayerService castService,
  required JellyfinClientService jellyfinClientService,
  required LocalPlayerService localService,
  required MediaRemoteDataSource dataSource,
  required MediaUrlService urlGenerator,
  required PlayerTracker playerTracker,
})
```

```dart
// Initializer list — alpha
  : _castDeviceManager = castDeviceManager,
    _castService = castService,
    _dataSource = dataSource,
    _jellyfinClientService = jellyfinClientService,
    _localService = localService,
    _playerTracker = playerTracker,
    _urlGenerator = urlGenerator,
```

Do NOT reorder things where order is semantically meaningful (e.g. sequential operations in `initState`, widget tree, etc.).

## Record select pattern

Always use `context.select` — never `context.watch` — when reading from a Bloc.

```dart
final (:List<DownloadedMediaItem> episodes, :bool isLoading) = context.select(
  (DownloadsBloc bloc) => (
    episodes: bloc.state.offlineLibrary
        .where((d) => d.media.type == MediaItemType.episode)
        .toList(),
    isLoading: bloc.state.isLoading,
  ),
);
```

- Use `context.select` without explicit generic type parameters
- Use a named function parameter (`(DownloadsBloc bloc)`) instead of `(b)`
- Return a named record with fields alpha-sorted by key
- Destructure with `:Type name` syntax, also alpha-sorted
