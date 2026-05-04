# Android Module Architecture

This document outlines the refactored architecture of the LunarDatePicker Android module, following clean architecture principles and Android best practices.

## Package Structure

```
com.margelo.nitro.lunardatepicker/
├── LunarDatePicker.kt                    # Main entry point
├── LunarDatePickerPackage.kt            # React Native package
├── constants/                           # NEW: Organized constants
│   ├── UIConstants.kt                   # UI-related constants
│   ├── LayoutConstants.kt               # Layout dimensions and styles
│   └── DataConstants.kt                 # Data formats and calculations
├── coordinators/                        # Presentation coordinators
│   └── LunarDatePickerCoordinator.kt    # Main flow coordinator
├── exceptions/                          # Custom exceptions
│   └── LunarDatePickerException.kt      # Exception types
├── models/                              # Data models
│   ├── DateSelection.kt                 # Date selection state
│   ├── PickerConfig.kt                  # Configuration models
│   └── SerializableRange.kt             # Serializable range wrapper
├── repositories/                        # NEW: Data repositories
│   └── PriceRepository.kt               # Price data management
├── services/                            # Business logic services
│   └── ConfigurationBuilder.kt          # Configuration building
├── ui/                                  # NEW: UI components
│   ├── fragments/                       # Fragment implementations
│   │   └── LunarDatePickerFragment.kt   # Main fragment
│   ├── viewholders/                     # ViewHolder classes
│   │   ├── DayViewHolder.kt             # Day cell view holder
│   │   └── MonthViewHolder.kt           # Month header view holder
│   └── builders/                        # UI builder classes
│       └── UIBuilder.kt                 # UI component factory
└── utils/                               # Utility classes
    ├── ColorUtils.kt                    # Color operations
    ├── ContinuousSelectionHelper.kt     # Selection logic
    ├── DateConverter.kt                 # Date conversions
    ├── DimensionUtils.kt                # Dimension utilities
    └── TimeZoneExtensions.kt            # TimeZone extensions
```

## Architecture Principles

### 1. Separation of Concerns
- **UI Layer**: Fragments, ViewHolders, and UI builders handle presentation
- **Business Logic**: Services and coordinators handle business rules
- **Data Layer**: Repositories manage data access and caching

### 2. Dependency Injection
- Dependencies are injected via constructor parameters
- Interfaces are used for better testability
- Lazy initialization for performance optimization

### 3. Clean Code Practices
- Single Responsibility Principle: Each class has one clear purpose
- Open/Closed Principle: Classes are open for extension, closed for modification
- Dependency Inversion: High-level modules don't depend on low-level modules

## Key Components

### LunarDatePickerFragment
- **Location**: `ui/fragments/LunarDatePickerFragment.kt`
- **Purpose**: Main UI component for date selection
- **Features**:
  - Clean lifecycle management
  - Proper dependency injection
  - Optimized scroll performance
  - Separated view creation logic

### ViewHolders
- **DayViewHolder**: Handles individual day cell rendering
- **MonthViewHolder**: Handles month header rendering
- **Benefits**: Improved performance, better code organization

### PriceRepository
- **Purpose**: Manages price data with optimized updates
- **Features**:
  - Batch updates for performance
  - Memory-efficient data storage
  - Price statistics calculations

### Constants Organization
- **UIConstants**: UI-related constants (colors, dimensions, etc.)
- **LayoutConstants**: Layout and styling constants
- **DataConstants**: Data formats, calculations, and business constants

## Performance Optimizations

### 1. Scroll Performance
- Optimized ViewHolder recycling
- Efficient price data updates
- Reduced memory allocations

### 2. Memory Management
- Weak references for callbacks
- Proper cleanup in lifecycle methods
- Efficient data structures

### 3. UI Responsiveness
- Lazy initialization of heavy components
- Background thread operations
- Optimized layout calculations

## Testing Strategy

### Unit Tests
- Services and utilities are easily testable
- Mock dependencies for isolated testing
- Business logic separated from UI

### Integration Tests
- Repository integration tests
- Coordinator flow tests
- UI component tests

## Migration Guide

### Constants Migration (Completed)
The old `Constants.kt` file has been completely replaced with organized constant files:

```kotlin
// NEW organized structure
UIConstants.Handle.WIDTH                 # UI-related constants
LayoutConstants.TextSize.DAY_TEXT        # Layout and dimensions
DataConstants.LogTags.FRAGMENT           # Data formats and calculations
```

### Architecture Changes (Completed)
- Fragment moved to `ui/fragments/` package
- ViewHolders extracted to separate classes in `ui/viewholders/`
- UI building logic moved to `UIBuilder` in `ui/builders/`
- Price management moved to `PriceRepository` in `repositories/`

## Best Practices

### 1. Code Organization
- Group related functionality in appropriate packages
- Use meaningful names for classes and methods
- Keep classes focused on single responsibilities

### 2. Performance
- Use lazy initialization for expensive operations
- Implement proper view recycling
- Minimize object allocations in hot paths

### 3. Maintainability
- Document public APIs
- Use constants instead of magic numbers
- Implement proper error handling

## Future Enhancements

### 1. Dependency Injection Framework
- Consider using Dagger/Hilt for better dependency management
- Implement proper scoping for components

### 2. State Management
- Consider using ViewModels for better state management
- Implement proper state persistence

### 3. Testing
- Add comprehensive unit and integration tests
- Implement UI testing with Espresso

## Contributing

When adding new features:
1. Follow the established package structure
2. Use appropriate constants from the constants package
3. Implement proper error handling
4. Add documentation for public APIs
5. Consider performance implications

This architecture provides a solid foundation for maintainable, testable, and performant code. 