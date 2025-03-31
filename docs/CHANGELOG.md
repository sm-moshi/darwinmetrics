# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- Architecture detection not implemented yet
- Test coverage incomplete

## [Unreleased]

### Planned

- Implement architecture detection
- Add real metric collection for all modules
- Complete test coverage
- Add async sampling support
- Add exporters (Prometheus, InfluxDB)

<!-- markdownlint-configure-file
MD024:
  # Only check sibling headings
  siblings_only: true
-->
