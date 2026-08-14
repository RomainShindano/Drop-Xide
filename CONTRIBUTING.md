# Contributing to Drop-Xide

Thank you for your interest in contributing to Drop-Xide! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected vs actual behavior**
- **Screenshots** if applicable
- **Environment details** (OS, Flutter version, etc.)

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- **Clear use case** for the enhancement
- **Detailed description** of the proposed functionality
- **Mockups or examples** if applicable

### Pull Requests

1. **Fork the repository** and create your branch from `master`
2. **Follow the coding style** used throughout the project
3. **Write clear commit messages**
4. **Include tests** for new functionality
5. **Update documentation** as needed
6. **Ensure all tests pass** before submitting

## Development Setup

1. Install Flutter SDK (3.13.0 or higher)
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/Drop-Xide.git
   cd Drop-Xide
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run -d linux  # or macos, windows
   ```

## Coding Standards

### Dart Style Guide

- Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter format` to format your code
- Run `flutter analyze` to check for issues

### Code Organization

- **Models**: Data classes with JSON serialization
- **Services**: Business logic and external integrations
- **Providers**: State management
- **Screens**: Full-page UI components
- **Widgets**: Reusable UI components
- **Utils**: Helper functions and utilities

### Naming Conventions

- **Files**: lowercase_with_underscores.dart
- **Classes**: PascalCase
- **Variables/Functions**: camelCase
- **Constants**: SCREAMING_SNAKE_CASE

### Documentation

- Add doc comments for public APIs
- Include usage examples for complex functionality
- Update README.md when adding features

## Testing

- Write unit tests for services and utilities
- Write widget tests for UI components
- Ensure test coverage for new features
- Run tests before submitting:
  ```bash
  flutter test
  ```

## Commit Messages

Use clear and descriptive commit messages:

```
feat: Add build cancellation feature
fix: Resolve project path validation issue
docs: Update installation instructions
style: Format build service code
test: Add tests for project provider
refactor: Simplify build configuration logic
```

### Commit Message Format

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

## Review Process

1. Submit your pull request
2. Automated tests will run
3. A maintainer will review your changes
4. Address any feedback
5. Once approved, your PR will be merged

## Questions?

Feel free to open an issue for questions or reach out to the maintainers.

Thank you for contributing to Drop-Xide! 🎉
