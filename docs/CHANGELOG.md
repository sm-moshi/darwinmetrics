# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.3] - 2024-04-01

### Added

- Platform detection module with Darwin version validation
- Minimum macOS version requirement set to 12.0+ (Darwin 21.0+)
- Comprehensive test suite for platform detection

### Changed

- Updated platform requirements in documentation
- Enhanced error handling for version checks

### Fixed

- None

## [0.0.2] - 2024-04-01

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

## [0.0.1] - 2024-04-01

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

## [Unreleased]

### Planned

- Add real metric collection for all modules
- Complete test coverage
- Add async sampling support
- Add exporters (Prometheus, InfluxDB)

<!-- markdownlint-configure-file
MD024:
  # Only check sibling headings
  siblings_only: true
-->
