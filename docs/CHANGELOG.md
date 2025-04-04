# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.7] - 2025-04-04

### Added

- Comprehensive power monitoring module:
  - Battery status and charge level detection
  - Power source identification (AC/battery/UPS)
  - Remaining time and battery health metrics
  - Thermal pressure level detection
  - Low power mode information
  - Time remaining and time to full charge estimates
  - Battery cycle count and condition reporting
  - Clean public API with full documentation
- Enhanced testing:
  - Stress testing for stability
  - Logical consistency validation
  - Data format validation
  - Cross-check testing between different metrics
- Implemented robust Chronos-based metric collection system:
  - Added `MetricCollector` type with configurable timeouts and error handling
  - Implemented async collection methods for CPU, memory, power, and process metrics
  - Added parallel collection via `collectAll` for efficient metric gathering
  - Introduced periodic sampling with configurable intervals
  - Added comprehensive error handling and propagation
  - Added proper cleanup and cancellation in async operations
  - Added type-safe metric value handling with proper timestamps
  - Added snapshot retention with configurable limits
  - Added proper timeout handling (5s default)
  - Added comprehensive test coverage for all scenarios

### Changed

- Improved IOKit and CoreFoundation bindings
- Enhanced error handling for battery-related operations
- Added safer memory management for C types
- Refactored metric collection architecture:
  - Moved to Chronos-based async implementation for better performance
  - Enhanced error context with metric-specific information
  - Improved memory management with efficient metric pruning
  - Updated power metrics to use battery percentage as proxy
  - Enhanced test suite with async-aware testing
- Enhanced documentation across sampling system:
  - Added comprehensive architectural overview in sampling modules
  - Improved async examples with proper error handling
  - Added thread safety and performance documentation
  - Updated CPU module docs with async best practices
  - Added integration examples between components
  - Improved code examples in all modules
  - Added clear separation between sync/async APIs
  - Enhanced documentation for backend-agnostic design

### Removed

- Removed legacy sampling implementations:
  - Removed `sampling_chronos.nim` in favor of new implementation
  - Removed `sampling_core.nim` as part of architecture redesign
  - Removed `sampling_stdlib.nim` to standardize on Chronos

## [0.0.6] - 2025-04-01

### Added

- Memory management improvements:
  - Implemented public memory API with clean abstraction
  - Added memory pressure level monitoring
  - Added process memory information tracking
  - Added comprehensive memory statistics
  - Added memory unit constants (KB, MB, GB, TB)
  - Added proper error handling and type safety

### Changed

- Refactored memory types into separate modules:
  - Moved internal Mach types to `memory_types.nim`
  - Created clean public API in `memory.nim`
  - Improved documentation and examples
- Enhanced error handling in memory operations
- Improved type safety across memory management
- Enhanced CPU module documentation:
  - Added comprehensive examples and usage patterns
  - Improved type descriptions and field documentation
  - Added platform-specific notes for Apple Silicon/Intel
  - Matched documentation style with memory module
  - Added clear separation between low-level and high-level interfaces

## [0.0.5] - 2025-04-01

### Added

- CPU frequency detection:
  - Support for Apple Silicon (M1/M2) frequency reporting
  - Intel CPU frequency detection with brand string fallback
  - Flexible frequency tests for cross-architecture support
  - Per-core CPU usage tracking:
  - Added `getPerCoreCpuLoadInfo()` to get per-core load statistics
  - CPU usage tracking with user/system/idle/nice percentages
  - Thread-safe load history monitoring with locks
  - Async load average monitoring interface

### Changed

- **BREAKING**: Removed DarwinError from getFrequencyInfo for graceful fallbacks
- Made frequency detection more resilient across architectures
- Enhanced error handling with reasonable defaults for different CPU types
- Memory management in CPU metrics:
  - Corrected vm_deallocate header import from <mach/mach_vm.h> to <mach/vm_map.h>
  - Fixed memory deallocation after retrieving per-core CPU information
  - Properly exported Mach kernel functions for cross-module use
  - Improved import structure for better code organization
- Refactored CPU module to use selective imports
- Enhanced thread safety in load history tracking
- Added proper type annotations for Mach kernel bindings

## [0.0.4] - 2025-04-01

### Added

- CPU load average monitoring:
  - LoadAverage type with 1/5/15-minute averages
  - Historical load tracking with configurable sample size
  - Mach kernel statistics integration
  - Timestamp validation and chronological ordering
  - Comprehensive test coverage

### Changed

- Enhanced CPU metrics module structure
- Improved test suite reliability

### Fixed

- Deque handling in LoadHistory tests
- Timestamp validation in load average tracking

## [0.0.3] - 2025-04-01

### Added

- Platform detection module with Darwin version validation
- Minimum macOS version requirement set to 12.0+ (Darwin 21.0+)
- Comprehensive test suite for platform detection

### Changed

- Updated platform requirements in documentation
- Enhanced error handling for version checks

### Fixed

- None

## [0.0.2] - 2025-04-01

### Added

- Development tooling and tasks:
  - Formatter (nimpretty) task
  - Static analysis task
  - ThreadSanitizer compatibility and test
  - CI task runner
- Platform detection features:
  - Darwin architecture detection (arm64/x86_64)
  - Version validation and requirements
  - Comprehensive test coverage

### Changed

- Updated development workflow with new tasks
- Enhanced platform compatibility checks

## [0.0.1] - 2025-04-01

### Added

- Initial project structure and setup
- Basic module stubs for system metrics
- GitHub Actions workflows for build and release
- Project documentation:
  - README with project overview and setup instructions
  - ROADMAP.md with development phases
  - TODO.md with detailed task tracking
  - CODE_OF_CONDUCT.md for community guidelines
- Development configuration:
  - .editorconfig for consistent coding style
  - .gitignore for Nim projects
  - Nimble package configuration

### Changed

- None (initial release)

### Fixed

- None (initial release)

### Known Issues

- All metric modules return placeholder messages
- Test coverage incomplete

<!-- markdownlint-configure-file
MD024:
  # Only check sibling headings
  siblings_only: true
-->
