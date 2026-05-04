# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-05-05

### Added
- Initial release of `@2security/lunar-date-picker`.
- Full lunar calendar support with Vietnamese calculations.
- Cross-platform support (iOS & Android) using Nitro Modules for native performance.
- Optimized Android rendering using `kizitonwose/Calendar` library (60% faster scrolling).
- Timezone-aware date operations and lunar calculations.
- Price integration with "cheapest" highlighting and dynamic updates.
- Lazy loading for prices with accurate month visibility callbacks (debounced).
- Single and range date selection modes.
- Customizable themes (light/dark) and multi-language support (Vietnamese, English).
- Customizable assets for "from", "to", and "close" icons.
- Smart hash-based change detection to prevent unnecessary re-renders.

### Fixed
- Improved Android UI consistency for submit and close buttons.
- Optimized icon rendering and scaling on both platforms.

---

[Unreleased]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/duongnguyen17/react-native-lunar-date-picker/releases/tag/v1.0.0

