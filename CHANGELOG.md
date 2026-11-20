# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **JS & Native**: Exported standalone `getLunarDate(date, timeZoneOffset = 7)` and `getLunarMonth(year, month, timeZoneOffset = 7)` functions accessible via synchronous Nitro JSI calls, enabling high-performance lunar date lookups in custom React Native calendar components without presenting the native picker UI. Mặc định `timeZoneOffset = 7` (chuẩn UTC+7 cho Âm lịch Việt Nam).
- **iOS & Android**: Native implementations for standalone lunar calculation using pre-existing `LunarMonthSpanCache` and exact trigonometric oracles with default fallback to UTC+7.
- **Example**: Added interactive standalone lunar API test section in `example/src/screens/HomeScreen.tsx` demonstrating single-day conversion and full-month batch conversion with execution timing.

## [1.3.2] - 2026-11-19

### Fixed

- **Android**: Apply the configured month title color so it follows the selected theme, including dark mode.

## [1.3.1] - 2026-11-17

### Fixed

- **iOS**: Use the picker's configured calendar and timezone for day labels and minimum/maximum date bounds, preventing incorrect dates when the device timezone differs.
- **iOS**: Raise lunar-date and price labels slightly so they fit within the rounded selected-day background.

### Changed

- **iOS**: Refresh only dates whose price or cheapest-price styling changed when `updatePrices` replaces the price snapshot. Price updates are applied on the main thread and deferred until the calendar is ready when necessary.

### Added

- **iOS**: Added a regression script covering price additions, changes, removals, and unchanged snapshots.

## [1.3.0] - 2026-11-17

### Added

- **iOS & Android**: Lunar month span cache (`LunarMonthSpanCache`) — a bounded LRU cache (24 spans) that records month-level metadata from exact lunar calculations and infers days 1–29 (or 1–30 when confirmed) without recalculating. Reduces expensive trigonometric calls by **~95%** for sequential calendar access; benchmarked at **5× faster** warm-cache conversions compared to the exact oracle.
- **Android**: Targeted calendar invalidation (`CalendarInvalidation`) — diffs selection and price changes to refresh only the affected months via `notifyMonthChanged()` instead of full `notifyCalendarChanged()` redraws, significantly reducing UI jank during interactions.
- **Android**: `VietnameseLunarDateCalculator` — extracted standalone, stateless lunar date conversion oracle for clean separation of concerns and independent testability.
- **Android**: 20 new unit tests covering `CalendarInvalidation` (11 tests) and `LunarMonthSpanCache` (9 tests), including oracle-based correctness verification across 12 years × 3 timezones, concurrent safety, and boundary conditions.
- **iOS**: Regression test scripts for lunar cache and span cache (`scripts/`) covering 800 years × 4 timezones with exact oracle comparison.

### Changed

- **iOS & Android**: Replaced over-engineered object pooling (`ObjectPool`, `GradientDrawablePool`, `MemoryOptimizer`) and configuration caching (`ConfigurationCacheService`) with simple lazy-initialized per-ViewHolder drawables and formatters, removing ~560 lines of unnecessary complexity.
- **iOS & Android**: Extracted exact lunar math into a standalone calculator (Kotlin) / renamed to `getVietnameseLunarDateExact` (Swift), keeping the trigonometric oracle isolated.
- **Android**: `preloadLunarDateCache` is now a `suspend` function with cooperative cancellation via `ensureActive()`.
- **Android**: `prewarmLunarCache()` skips work when `showLunarDate` is false, targets only 3 months from the selected/today date instead of a fixed window, and respects min/max date bounds.
- **iOS**: `LunarPersistentCache` disk writes use a dedicated serial queue instead of `DispatchQueue.global` to prevent write contention; eviction logic extracted into reusable `evictIfNeeded()`.
- **iOS**: `PickerController.lunarCacheKey()` converted to `static func` to eliminate `self` capture in background prewarm; `formatPrice()` reuses a lazy `priceFormatter` instead of allocating per cell.
- **iOS**: `prewarmLunarCache()` early-returns when `showLunarDate` is false.

### Removed

- **Android**: Deleted `ObjectPool.kt` (229 lines), `MemoryOptimizer.kt` (51 lines), `ConfigurationCacheService.kt` (277 lines), and inline lunar math from `DateConverter.kt` (~144 lines).

## [1.2.2] - 2026-09-26

### Fixed

- **iOS & Android**: Standardized calendar weeks to run Monday through Sunday regardless of locale, keeping weekday labels aligned with dates.

### Added

- **Example**: Added Vietnamese and English language switching for single-date and range picker flows.

## [1.2.1] - 2026-09-26

### Changed

- **iOS & Android**: Made `timeZoneOffset` optional. Configured fixed UTC offsets support fractional hours; omitting the value uses the device timezone.

### Fixed

- **iOS & Android**: Applied the resolved timezone consistently to date input, selection bounds, returned dates, and lunar calculations.

## [1.2.0] - 2026-08-14

### Added

- **iOS & Android**: Added `updateMaximumDate(maximumDate: string)` function to dynamically update the maximum selectable date while the calendar is open (e.g. inside `onSelectFromDate` callback to restrict range selection).

### Maintenance

- Upgraded dependencies including React Native 0.87.0 and `react-native-nitro-modules` 0.36.5.

## [1.1.3] - 2026-06-28


### Fixed

- **iOS & Android**: Refined day cell layout spacing and text sizes for better visual balance.

## [1.1.2] - 2026-06-28

### Fixed

- **Android**: Fixed `showLunarDate` updates being ignored by `ConfigurationCacheService`.
- **iOS & Android**: Refactored cell layouts to maintain a strictly fixed 42x42 selection circle.
- **iOS & Android**: Preserved vertical text alignment across the calendar by reserving space for empty price data.
- **Android**: Removed text padding (`includeFontPadding`) to prevent vertical clipping.
- **iOS & Android**: Dynamically increased price text font size when lunar dates are hidden.

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

[Unreleased]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.2.1...HEAD
[1.2.1]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.1.3...v1.2.0
[1.1.3]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.1.2...v1.1.3

[1.1.2]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.0.3...v1.1.0
[1.0.3]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/duongnguyen17/react-native-lunar-date-picker/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/duongnguyen17/react-native-lunar-date-picker/releases/tag/v1.0.0
