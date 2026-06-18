# Changelog

All notable changes to Playcado will be documented in this file.

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
