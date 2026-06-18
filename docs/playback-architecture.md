# Playback Architecture

## Overview

Playback uses an **engine adapter pattern** with a strict **unidirectional data flow** (UDF):

```
UI ──event──▶ PlayerBloc ──load/play/pause──▶ PlayerService
                  ▲                               │
                  │              stateStream       │
                  └─────────────── listen ─────────┘
```

Two `PlayerService` implementations handle different backends:

| Service | Backend | PlayerView |
|---------|---------|------------|
| `LocalPlayerService` | `media_kit` | `LocalPlayerView` (contains `VideoController`) |
| `CastPlayerService` | `flutter_chrome_cast` | `CastPlayerView` (placeholder — no local video) |

`CastDeviceService` is a separate concern — it handles **device discovery and session management** (finding Chromecasts, connecting/disconnecting). Media playback on a connected Cast device goes through `CastPlayerService`.

## Key Types

### `PlayerService` (abstract, `lib/player/services/player_service.dart`)

Interface that both local and cast services implement:

- `load(PlayableMedia)` — open a media source
- `play()` / `pause()` / `seek()` / `stop()`
- `setAudioTrack()` / `setSubtitleTrack(index)` — track switching (cast stubs)
- `stateStream` — emits `PlayerServiceState` with position, duration, isPlaying, isBuffering, isCompleted
- `playerView` — returns a `PlayerView` sealed class for the UI to render

### `PlayerServiceState`

Thin value class emitted on `stateStream`:

```
position, duration, isPlaying, isBuffering, isCompleted
```

### `PlayableMedia` (`lib/player/models/playable_media.dart`)

The normalized model passed to `PlayerService.load()`. Created in `PlayerBloc._buildPlayableMedia()`:

- For **local playback**: stream URL + auth headers, or local file path
- For **cast**: transcoded URL (via `_urlGenerator.generateTranscodeUrl`), poster image

### `PlayerBloc` (`lib/player/bloc/player_bloc.dart`)

Orchestrates playback. Key responsibilities:

- Selects the active service based on context (`_localService` vs `_castPlayerService`)
- Builds `PlayableMedia` from `MediaItem` (resolves URLs, handles auth)
- Subscribes to `PlayerService.stateStream` and re-emits as `ServiceStateUpdated`
- Reports progress to `PlayerTrackerRepository` every 10s during local playback
- Handles cast session lifecycle — if `CastDeviceService` disconnects while casting, emits `PlayerStopRequested`

### `CastDeviceService` (`lib/cast/services/cast_device_service.dart`)

Manages the Google Cast session lifecycle only — not media playback:

- `initialize()` — sets platform Cast options, starts device discovery
- `connect(GoogleCastDevice)` — starts a session
- `disconnect()` — ends session
- `devicesStream` / `currentSessionStream` — reactive device/session state
- `waitUntilConnected()` — await a successful connection

### `PlayerTrackerRepository` (`lib/player/repositories/player_tracker_repository.dart`)

Reports server-side playback telemetry (start, progress, stop, played/unplayed toggle). Thin wrapper over `MediaRemoteDataSource` with logging.

## Data Flow: Play Request

1. **UI** dispatches `PlayerPlayRequested(item:, localPath:)`
2. **PlayerBloc._onPlayRequested** checks `CastDeviceService.isConnected`:
   - If **connected**: switches to `_castPlayerService`, builds a transcode URL, calls `load()`
   - If **not connected**: switches to `_localService`, builds a stream URL with auth headers (or uses local path), calls `load()`. Reports playback start to `PlayerTrackerRepository`
3. **PlayerService.load()** opens the media and starts playback
4. **PlayerService.stateStream** emits position/duration/status updates
5. **PlayerBloc** listens via `ServiceStateUpdated` and re-emits to `PlayerState`
6. **UI** renders via `BlocBuilder<PlayerBloc, PlayerState>`

## Cast vs Local Decision Logic

| Condition | Active Service |
|---|---|
| Cast device connected & play requested | `CastPlayerService` |
| Cast device connected & cast explicitly requested | `CastPlayerService` |
| No cast device | `LocalPlayerService` |
| Cast device disconnects during playback | `PlayerBloc` emits `PlayerStopRequested` |

## UI Components

| Widget | File | Role |
|--------|------|------|
| `PlayerView` (sealed) | `player_service.dart` | `LocalPlayerView` wraps `VideoController`; `CastPlayerView` is a placeholder |
| `FullscreenPlayerScreen` | `player/views/` | Full-screen player, renders either local video or `CastControlView` |
| `MiniPlayer` | `player/views/` | Persistent bottom bar showing now-playing |
| `VideoControlsOverlay` | `player/widgets/` | Play/pause, seek, skip intro, track selection |
| `CastControlView` | `player/widgets/` | "Casting to device..." UI shown during cast playback |
| `CastDeviceListDialog` | `cast/widgets/` | Bottom sheet listing discovered Chromecast devices |
| `TrackSelectionSheet` | `player/widgets/` | Audio/subtitle track picker (local playback only) |
