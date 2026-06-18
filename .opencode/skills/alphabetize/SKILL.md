---
name: alphabetize
description: Use for any code editing task in Dart/Flutter files. Always sort members, imports, fields, methods, parameters, and groups alphabetically when creating or modifying source code.
---

# Alphabetize

Apply alphabetical ordering throughout Dart/Flutter source files:

1. **Imports** — Sort alphabetically by package path within each import group (dart:, package:, relative).
2. **Classes** — Sort members alphabetically: fields first, then getters/setters, then methods.
3. **Constructor parameters** — Sort alphabetically.
4. **Initializer list** — Sort alphabetically.
5. **Event registrations** (`on<...>`) — Sort alphabetically by event name.
6. **Switch cases / if-else chains** — Sort alphabetically where order is not semantically meaningful.
7. **Method parameters** — Sort alphabetically.
8. **Public before private** — Within each group, public members precede private ones, then alpha-sorted.

## Examples

```dart
// Before
final String name;
final int age;
String? nickname;

// After
String? nickname;
final String name;

// Wait — no: public before private, then alpha
final String name;
String? nickname;
final int age;

// Correct:
final String name;
final int age;
String? nickname;
```

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
// Constructor params — alpha
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
