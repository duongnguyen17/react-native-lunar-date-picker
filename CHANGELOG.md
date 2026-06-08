# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.1] - 2026-06-08

### Fixed

- **iOS**: Stopped calendar scrolling when dismissing the picker to prevent `JTAppleCalendar` assertion failures.
- **iOS**: Resolved an issue on iPad where calendar columns incorrectly expanded based on the initial full-screen container bounds instead of the FormSheet size.

## [1.1.0] - 2026-06-08

### Added

- Implemented a fluid typography and layout scaling system (390px base to 430px cap) to ensure consistent UI across different screen sizes on both platforms.

### Changed

- **iOS**: Upgraded iPad presentation to use native Form Sheet sizing by removing hardcoded constraints, providing a more standard tablet experience.
- **Android**: Enhanced tablet presentation (≥ 540dp) to use a centered, 4-corner rounded Dialog replicating the iPad Form Sheet behavior, rather than a full-width Bottom Sheet.

## [1.0.3] - 2026-05-12

### Changed

- Updated `updatePrices` behavior to perform a full sync (replacing existing price data with the new list) instead of merging. This ensures dates missing from the new data are cleared from the UI.

## [1.0.2] - 2026-05-12

### Fixed

- Fixed `onSelectFromDate` callback not triggering on iOS and Android when `showSubmitButton` is set to `false`.

## [1.0.1] - 2026-05-05

### Fixed

- Fixed image visibility issues on NPM by using absolute GitHub Raw URLs for demo GIFs.
- Included `assets` directory in the NPM package files.
- Optimized demo video sizes in README for a more consistent and professional side-by-side layout.
- Added Expo Usage guide to README for Development Builds.

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
- **Added `notice` banner support** below the navigation bar for both iOS and Android.
- Added `noticeLabelColor` and `noticeBackgroundColor` to `LDP_CustomStyle` for banner customization.
- Updated `onMounted` and `onSelectFromDate` callbacks to provide the full visible/selectable date range (`startDate`, `endDate`).

### Changed

- Improved selected day highlight UI on Android using rounded rectangles with better padding.
- Optimized performance by removing redundant scroll listeners and month visibility tracking.
- Simplified `LDP_PriceUpdateParams` by removing the `month` field (pricing is now date-based).
- Reduced notice banner font size to 12 and vertical padding to 8 for a more compact look.

### Fixed

- Improved Android UI consistency for submit and close buttons.
- Optimized icon rendering and scaling on both platforms.
- Fixed layout loop issues and performance bottlenecks on iOS.
- Resolved memory leak patterns on Android's native calendar view.

### Removed

- Removed `onMonthVisible` callback from `LDP_PresentParams`.
- Removed native scroll listening logic for currently visible months.

### Documentation & Assets

- Added professional demo GIFs for iOS and Android in the README.
- Organized repository assets into a dedicated `assets/` directory.
- Updated README with a comprehensive "Preview" section and refined API documentation.

---

[Unreleased]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.1.1...HEAD
[1.1.1]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.0.3...v1.1.0
[1.0.3]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/duongnguyen17/react-native-lunar-date-picker/releases/tag/v1.0.0
