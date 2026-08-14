# Changelog

All notable changes to Drop-Xide will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-08-14

### Added
- Initial release of Drop-Xide
- Project management system
  - Add Flutter projects
  - Validate Flutter projects
  - Project list view
  - Delete projects
- Build configuration
  - Multiple platform support (Android, iOS, Web, Linux, macOS, Windows)
  - Build mode selection (Debug, Profile, Release)
  - Advanced build options (flavors, obfuscation, split debug info)
- Build automation
  - One-click building
  - Real-time build logs
  - Build progress monitoring
  - Automatic output organization
- Build history
  - Complete build history tracking
  - Status indicators
  - Duration tracking
  - Error reporting
  - Quick access to build outputs
- Google Play Store integration (backend ready)
  - Service account management
  - API integration for future publishing
- Modern UI
  - Material Design 3
  - Dark/Light theme support
  - Responsive layout
  - Navigation rail
- Error handling
  - Comprehensive exception system
  - User-friendly error messages
  - Error dialogs and notifications
- Testing
  - Unit tests for models and utilities
  - Test infrastructure setup
- Documentation
  - Comprehensive README
  - Contributing guidelines
  - MIT License
  - Code documentation

### Technical Details
- Built with Flutter 3.47.0
- State management with Provider
- Local storage with SQLite
- JSON serialization with json_serializable
- Window management with window_manager
- Process execution with process_run
- Google APIs integration with googleapis

[1.0.0]: https://github.com/RomainShindano/Drop-Xide/releases/tag/v1.0.0
