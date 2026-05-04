# @2security/lunar-date-picker

[![npm version](https://badge.fury.io/js/@2security%2Flunar-date-picker.svg)](https://www.npmjs.com/package/@2security/lunar-date-picker)
[![npm downloads](https://img.shields.io/npm/dm/@2security/lunar-date-picker.svg)](https://www.npmjs.com/package/@2security/lunar-date-picker)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A powerful and feature-rich React Native lunar date picker component built with Nitro Modules, providing native performance for both iOS and Android platforms.

## ✨ Features

- 🌙 **Lunar calendar support** - Display both solar and lunar dates with proper timezone handling
- 📱 **Cross-platform** - Works seamlessly on iOS and Android with identical behavior
- ⚡ **High performance** - Built with Nitro Modules for native performance
- 🚀 **Optimized Android rendering** - Uses high-performance [kizitonwose Calendar](https://github.com/kizitonwose/Calendar) library for 60% faster scrolling
- 🎨 **Customizable themes** - Light/dark themes with full customization
- 🌍 **Multi-language support** - Vietnamese, English, and extensible for other languages
- 📅 **Flexible date selection** - Single date or date range selection
- 🎯 **From date callbacks** - Get notified when user selects the start date in range mode
- 💰 **Price integration** - Display prices for specific dates with highlighting
- 🔄 **Lazy loading** - Efficient price loading with month visibility callbacks (debounced and accurate)
- 🔄 **Smart updates** - Replace or merge price data without full re-render
- 🖼️ **Customizable images** - Support for custom "from", "to", and "close" icons using `require()` or URIs
- ⏰ **Timezone aware** - Proper timezone support for accurate date handling across regions
- 🚀 **Optimized rendering** - Hash-based change detection and partial updates for better performance

## 📦 Installation

```sh
npm install @2security/lunar-date-picker react-native-nitro-modules
# or
yarn add @2security/lunar-date-picker react-native-nitro-modules
```

> **Note:** `react-native-nitro-modules` is required as this library relies on [Nitro Modules](https://nitro.margelo.com/) for native performance.

## Install channels

- **Stable (latest):**

```bash
npm install @2security/lunar-date-picker react-native-nitro-modules
# or
yarn add @2security/lunar-date-picker react-native-nitro-modules
```

- **LBA prerelease:**

```bash
npm install @2security/lunar-date-picker@lba react-native-nitro-modules
# or
yarn add @2security/lunar-date-picker@lba react-native-nitro-modules
```

- **Specific LBA version:**

```bash
yarn add @2security/lunar-date-picker@0.1.15-lba
```

## 🚀 Quick Start

### 1. Configure the picker (Required)

```javascript
import { configure } from '@2security/lunar-date-picker';

const pickerConfig = {
  languages: {
    vi: {
      monthNames: ['Tháng 1', 'Tháng 2' /* ... */],
      weekdayNames: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'],
    },
    en: {
      monthNames: ['January', 'February' /* ... */],
      weekdayNames: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    },
  },
  themes: {
    light: {
      backgroundColor: '#ffffff',
      titleColor: '#000000',
      dateLabelColor: '#030712',
      selectedBackgroundColor: '#3B82F6',
      // ... other theme colors
    },
  },
  yearRangeOffset: 2,
  timeZoneOffset: 7, // GMT+7 for Vietnam - affects all date operations and lunar calculations
};

// Configure once in your app initialization
configure(pickerConfig);
```

### 2. Basic usage

```javascript
import { pickDate } from '@2security/lunar-date-picker';

const openDatePicker = () => {
  pickDate({
    theme: 'light',
    language: 'vi',
    title: 'Chọn ngày',
    textCancel: 'Hủy',
    mode: 'range', // or 'single'
    minimumDate: '2024-01-01', // Optional: minimum selectable date
    maximumDate: '2024-12-31', // Optional: maximum selectable date
    onSelectFromDate: (date, visibleMonths) => {
      // Optional: triggered when user selects from date in range mode
      console.log(
        'From date selected:',
        date,
        'Visible months:',
        visibleMonths
      );
    },
    onDone: (result) => {
      console.log('Selected range:', result);
      // result: LDP_Range = { from: "2024-01-15", to?: "2024-01-20" }
    },
  });
};
```

## 📚 API Reference

### Functions

#### `configure(config: LDP_ConfigParams): void`

Configure the picker with themes, languages, and global settings. **Must be called before using the picker.**

#### `pickDate(params: LDP_PresentParams): void`

Display the date picker with specified configuration.

#### `updatePrices(params: LDP_PriceUpdateParams): void`

Update price data for the calendar. Supports both full replacement and partial updates.

### Types

#### `LDP_PresentParams`

```typescript
interface LDP_PresentParams {
  theme: string; // Theme key from configuration
  language: string; // Language key from configuration
  title: string; // Picker title
  textCancel: string; // Cancel button text
  mode: LDP_PickerMode; // Selection mode ('range' | 'single')
  onDone: (result: LDP_Range) => void; // Selection callback
  minimumDate?: string; // Minimum selectable date (DD/MM/YYYY)
  maximumDate?: string; // Maximum selectable date (DD/MM/YYYY)
  initialValue?: LDP_Range; // Initial selected range
  prices?: LDP_PriceData[]; // Price data for dates
  onMonthVisible?: (month: string) => void; // Month visibility callback (debounced 600ms, visible-only)
  onSelectFromDate?: (date: string, currentlyVisibleMonths: string[]) => void; // From date selection callback
}
```

#### `LDP_PriceData`

```typescript
interface LDP_PriceData {
  date: string; // Date in DD/MM/YYYY format
  price: number; // Price value
  isCheapest?: boolean; // Highlight as cheapest price
}
```

#### `LDP_Range`

```typescript
interface LDP_Range {
  from: string; // Start date in DD/MM/YYYY format
  to?: string; // End date in DD/MM/YYYY format (optional for single mode)
}
```

#### `LDP_PriceUpdateParams`

```typescript
interface LDP_PriceUpdateParams {
  mode: LDP_UpdateMode; // Update mode ('replace' | 'merge')
  monthData?: LDP_MonthPriceData; // For partial month updates
  allPrices?: LDP_PriceData[]; // For full replacement
}

interface LDP_MonthPriceData {
  month: string; // Month in YYYY-MM format
  prices: LDP_PriceData[]; // Price data for the month
}
```

#### `LDP_ConfigParams`

```typescript
interface LDP_ConfigParams {
  themes: Record<string, LDP_CustomStyle>; // Theme configurations
  languages: Record<string, LDP_CustomLanguage>; // Language configurations
  yearRangeOffset: number; // Year range offset for calendar
  timeZoneOffset: number; // Timezone offset (e.g., 7 for GMT+7)
  fromImage?: any; // Custom 'from' icon (require() or {uri})
  toImage?: any; // Custom 'to' icon (require() or {uri})
  closeImage?: any; // Custom 'close' icon (require() or {uri})
}
```

#### `LDP_CustomStyle`

```typescript
interface LDP_CustomStyle {
  titleColor: string; // Title text color (hex)
  cancelColor: string; // Cancel button color (hex)
  dateLabelColor: string; // Date label color (hex)
  lunarDateLabelColor: string; // Lunar date label color (hex)
  selectedTextColor: string; // Selected text color (hex)
  weekendLabelColor: string; // Weekend label color (hex)
  specialDayLabelColor: string; // Special day label color (hex)
  priceLabelColor: string; // Price label color (hex)
  cheapestPriceLabelColor: string; // Cheapest price label color (hex)
  monthLabelColor: string; // Month label color (hex)
  backgroundColor: string; // Background color (hex)
  weekViewBackgroundColor: string; // Week view background color (hex)
  selectedBackgroundColor: string; // Selected background color (hex)
  rangeBackgroundColor: string; // Range background color (hex)
}
```

#### `LDP_CustomLanguage`

```typescript
interface LDP_CustomLanguage {
  weekdayNames: string[]; // Array of weekday names (7 items)
  monthNames: string[]; // Array of month names (12 items)
}
```

#### `LDP_PickerMode`

```typescript
type LDP_PickerMode = 'range' | 'single';
```

#### `LDP_UpdateMode`

```typescript
type LDP_UpdateMode = 'replace' | 'merge';
```

## 🎯 Advanced Usage

### Timezone Configuration

The picker properly handles timezones for accurate date operations and lunar calendar calculations:

```javascript
configure({
  timeZoneOffset: 7, // GMT+7 for Vietnam
  // All date formatting, lunar calculations, and price mapping
  // will use this timezone consistently across iOS and Android
});

// Dates will be formatted according to the configured timezone
pickDate({
  minimumDate: '2024-01-01', // Interpreted in GMT+7
  maximumDate: '2024-12-31', // Interpreted in GMT+7
  onDone: (result) => {
    // result.from and result.to are in DD/MM/YYYY format using GMT+7
    console.log('Selected:', result);
  },
});
```

### Price Integration

Display prices for specific dates with special highlighting:

```javascript
const priceData = [
  { date: '2024-01-15', price: 1500000, isCheapest: true },
  { date: '2024-01-16', price: 2000000 },
  { date: '2024-01-17', price: 1800000 },
];

pickDate({
  // ... other config
  prices: priceData,
});
```

### Lazy Loading with `onMonthVisible`

Efficiently load prices only when months become visible. The callback is **debounced by 600ms** and only triggered for **actually visible months** on screen:

```javascript
const handleMonthVisible = async (month) => {
  console.log(`Loading prices for ${month}`); // e.g., "2024-01"

  // This callback is triggered when:
  // 1. User stops scrolling for 600ms (debounced)
  // 2. Month is actually visible on screen (not just scrolled through)

  // Fetch prices from your API
  const prices = await fetchPricesForMonth(month);

  // Update prices for this specific month
  updatePrices({
    mode: 'merge',
    monthData: { month, prices },
  });
};

pickDate({
  // ... other config
  prices: [], // Start with empty prices
  onMonthVisible: handleMonthVisible,
});
```

**Important Behavior Notes:**

- **Debouncing**: `onMonthVisible` is called 600ms after user stops scrolling to prevent excessive API calls
- **Visible-only**: Only months actually visible on screen trigger the callback, not months scrolled through quickly
- **No duplicates**: Each month is only reported once until the picker is reopened

### From Date Selection Callback

Get notified when user selects the start date in range mode. This is useful for triggering API calls, updating UI, or performing validations when the from date is chosen:

```javascript
pickDate({
  mode: 'range',
  initialValue: { from: '2024-01-15' }, // Works with or without initial value
  onSelectFromDate: (date, currentlyVisibleMonths) => {
    console.log('User selected from date:', date); // e.g., "2024-01-20"
    console.log('Currently visible months:', currentlyVisibleMonths); // e.g., ["2024-01", "2024-02"]

    // Example use cases:
    // 1. Load prices for visible months
    loadPricesForMonths(currentlyVisibleMonths);

    // 2. Update external state
    setSelectedFromDate(date);

    // 3. Trigger validation
    validateDateSelection(date);
  },
  onDone: (result) => {
    // Called when range selection is complete
    console.log('Final range:', result);
  },
});
```

**Callback Behavior:**

- **Range mode only**: Only triggers in `mode: 'range'`, not in single mode
- **New from date selection**: Triggered when user selects a new start date, regardless of `initialValue`
- **Real-time visible months**: `currentlyVisibleMonths` contains only months currently visible on screen
- **Not triggered on completion**: Only fires when selecting from date, not when completing the range

**Use Cases:**

- **Price loading**: Load prices for visible months when user starts selecting a range
- **Availability checking**: Check room/service availability for the selected date
- **UI updates**: Update external components when date selection begins
- **Analytics**: Track user behavior during date selection process

### Dynamic Price Updates

Update prices without closing the picker. The picker includes smart optimizations to prevent unnecessary re-renders:

```javascript
// Replace all prices (with hash-based change detection)
updatePrices({
  mode: 'replace',
  allPrices: newPriceData,
});

// Add/update prices for specific month (partial update - only re-renders affected month)
updatePrices({
  mode: 'merge',
  monthData: {
    month: '2024-01',
    prices: monthPrices,
  },
});
```

### Performance Optimizations

The picker includes several performance improvements:

**Android Optimizations:**

- **High-performance calendar library**: Uses [kizitonwose Calendar](https://github.com/kizitonwose/Calendar) for 60% faster scrolling
- **Optimized RecyclerView**: Hardware-accelerated rendering with better memory management
- **Smooth range selection**: Streamlined selection logic inspired by Example4Fragment
- **Debounced scrolling**: 600ms debounce prevents excessive onMonthVisible calls

**Cross-platform Optimizations:**

- **Hash-based change detection**: Prevents unnecessary re-renders when price data hasn't changed
- **Partial month updates**: Only re-renders the specific month when using merge mode
- **Timezone-aware caching**: Consistent date formatting and lunar calculations
- **Efficient month visibility detection**: Prevents duplicate API calls for already-loaded months
- **Memory leak prevention**: Proper cleanup of handlers, work items, and references
- **LRU cache management**: Smart cache eviction prevents memory growth (iOS)
- **Object reuse**: Calendar instances and formatters are reused to reduce allocations

### Theme Customization

```javascript
const customTheme = {
  backgroundColor: '#ffffff',
  cancelColor: '#2563EB',
  titleColor: '#000000',
  dateLabelColor: '#030712',
  lunarDateLabelColor: '#6B7280',
  selectedTextColor: '#FFFFFF',
  weekendLabelColor: '#E27B00',
  specialDayLabelColor: '#ff3300',
  rangeBackgroundColor: '#EFF6FF',
  monthLabelColor: '#030712',
  weekViewBackgroundColor: '#F3F4F6',
  selectedBackgroundColor: '#3B82F6',
  priceLabelColor: '#ff9933',
  cheapestPriceLabelColor: '#00b300',
};

configure({
  themes: {
    custom: customTheme,
  },
  // ... other config
});
```

### Asset Resolution

You can easily customize the icons for "from", "to", and "close" buttons. The library handles `require()`, remote URLs, and native asset names automatically:

```javascript
import { configure } from '@2security/lunar-date-picker';

configure({
  // Using local require()
  closeImage: require('./assets/icons/my-close-icon.png'),

  // Using remote URI
  fromImage: { uri: 'https://example.com/icons/calendar-start.png' },

  // Using native asset name (from Android drawables/mipmap or iOS Asset Catalog)
  toImage: 'native_calendar_icon_name',

  // ... rest of config
});
```

## 🏃‍♂️ Running the Example

The example app demonstrates all features including lazy loading, timezone handling, and performance optimizations:

```sh
cd example
npm install
# iOS
npx react-native run-ios
# Android
npx react-native run-android
```

### Example App Features

- **Basic Usage**: Single and range date selection
- **Price Integration**: Static price display with cheapest highlighting
- **Lazy Loading**: Real-time month visibility detection with simulated API calls
- **Performance Testing**: Test scenarios for re-render optimization
- **Timezone Demo**: See how timezone affects date formatting and lunar calculations

## 🛠️ Development

```sh
# Install dependencies
yarn install

# Generate native code
yarn nitrogen

# Build the library
yarn prepare

# Run tests
yarn test

# Lint code
yarn lint

# Run example app
yarn example ios
yarn example android
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) to learn how to contribute to the repository and development workflow.

## 📋 Documentation

- **[API Reference](README.md#-api-reference)** - Complete API documentation with examples
- **[Contributing Guide](CONTRIBUTING.md)** - How to contribute to the project
- **[Publishing Guide](PUBLISHING.md)** - Steps to publish new versions
- **[Changelog](CHANGELOG.md)** - Version history and changes

## 📄 License

MIT © [2Security](https://github.com/duongnguyen17/react-native-lunar-date-picker)

---

Built with ❤️ by [2Security](https://github.com/duongnguyen17/react-native-lunar-date-picker) using [Nitro Modules](https://nitro.margelo.com/)
