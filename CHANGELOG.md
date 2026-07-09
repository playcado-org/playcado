# Changelog

All notable changes to Playcado will be documented in this file.

## [1.2.0]

### Added
- Recent searches now appear below the search bar, making it easy to revisit what you've been looking for (#21)
- Playcado is now live on the Play Store with a full listing, descriptions, and screenshots (#19, #18)

### Fixed
- Fixed a rare bug where a completed download could briefly show up in both active and completed sections at the same time (#20)

## [1.1.1]

### Added
- Tap links for feedback and legal pages — they now open right in the app instead of sending you to your browser (#16)

### Fixed
- Login screen no longer flashes before your saved accounts have loaded (#15)

## [1.1.0]

### Added
- Persist downloads to Drift SQLite, replacing DownloadsRepository with DownloadsManagerService (#10)

### Fixed
- Navigate to downloads manager tab when clicking downloaded button (#12)
- Improve logging across services (#11)

### Changed
- Remove GitHub MCP from project config (#9)

## [1.0.5]

### Fixed
- Close Jellyfin HTTP sessions to prevent connection leak (#3)
- Throttle position updates and add buildWhen to reduce video stutter (#4)
- Increase track selection sheet height and enable scroll control in bottom sheet (#5)

### Performance
- Reduce app startup time by ~800ms (#7)

### Changed
- Add dart-mcp-server to MCP config (#6)
- Enforce conventional commits via commitlint and PR title lint

## [1.0.4]

### Changed
- Rewrote git history with descriptive commit messages and squashed related commits

## [1.0.3]

### Changed
- Ignore `.opencode/` directory in git

## [1.0.2]

### Fixed
- Action button labels no longer clipped to a single line

## [1.0.1]

### Added
- Parallelized home content fetches so one slow section doesn't block others

### Fixed
- Prevent media_kit crash on hot-restart
- RangeError in Continue Watching carousel on refresh
- Update dependencies and pin Flutter SDK to 3.44.2

## [1.0.0]

### Added
- Initial Play Store release
- Library browsing with dashboard, paginated grids, and search
- Hardware-accelerated video playback with audio/subtitle selection
- Google Cast support for Chromecast and Android TV
- Offline downloads with background download manager
- Multi-server and multi-account support
- Material 3 theming with custom accent colors
- Sentry error tracking
- CI/CD: format → analyze → build_runner → build on push/PR
- Manual-dispatch release workflows for Android (Play Store) and iOS (TestFlight)
- Single release flavor, no dev/staging/prod
