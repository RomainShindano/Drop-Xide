# Drop-Xide

![appicon](https://github.com/user-attachments/assets/03aedc74-1b28-49c2-a0f1-4c439ec7742b)

**A comprehensive Flutter project build automation and deployment tool**

Drop-Xide is a powerful desktop application that streamlines the Flutter development workflow by providing centralized project management, automated building, and Google Play Store deployment capabilities.

## ✨ Features

### Current Features

#### 1. 📁 Project Management
- **Select Flutter Projects**: Browse and select Flutter projects from your filesystem
- **Project Validation**: Automatic validation of Flutter projects (checks for pubspec.yaml and Flutter dependencies)
- **Project List**: View all your Flutter projects in one organized interface
- **Add Multiple Projects**: Manage multiple Flutter projects simultaneously

#### 2. 🔧 Build Configuration
- **Platform Selection**: Build for Android, iOS, Web, Linux, macOS, and Windows
- **Build Modes**: Support for Debug, Profile, and Release builds
- **Advanced Options**:
  - Custom build flavors
  - Code obfuscation
  - Split debug information
- **Real-time Build Logs**: Monitor build progress with live log output

#### 3. 📦 Build Management
- **One-Click Building**: Start builds with a single click
- **Organized Output**: Builds automatically organized in `~/Dropxide/projectName/YYYY-MM-DD_HH-mm-ss/`
- **Build History**: Complete history of all builds with status tracking
- **Quick Access**: Open build output folders directly from the app

#### 4. 📊 Build History
- **Comprehensive Tracking**: View all past builds with detailed information
- **Status Indicators**: Visual status badges (Success, Failed, Running, Cancelled, Pending)
- **Duration Tracking**: See how long each build took
- **Error Reporting**: Detailed error messages for failed builds

### Upcoming Features

#### 🔐 Google Service Account Integration
- Upload and manage Google Service Account keys
- Secure credential storage
- OAuth 2.0 authentication
- Multiple service account support

#### 🚀 Automated Build and Publish
- Direct upload to Google Play Console
- Release track management (Internal/Alpha/Beta/Production)
- Automatic version code management
- Release notes generation
- Store listing updates

## 🖥️ Supported Platforms

- **Linux** (Primary platform)
- **macOS** (Full support)
- **Windows** (Full support)

## 📋 Requirements

- **Flutter SDK** 3.13.0 or higher
- **Dart SDK** (included with Flutter)
- **Git**
- **Platform-specific requirements**:
  - Linux: GTK 3.0, ninja-build
  - macOS: Xcode
  - Windows: Visual Studio 2019 or later

## 🚀 Installation

### From Source

1. Clone the repository:
```bash
git clone https://github.com/RomainShindano/Drop-Xide.git
cd Drop-Xide
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run -d linux  # or macos, windows
```

### Building from Source

To build a production release:

```bash
# Linux
flutter build linux --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release
```

The built application will be in the `build/` directory.

## 📖 Usage

### Adding a Project

1. Click the **+** button in the Projects tab
2. Browse and select your Flutter project directory
3. The app will validate and add the project to your list

### Building a Project

1. Select a project from the **Projects** tab
2. Navigate to the **Build** tab
3. Configure your build:
   - Select platform (Android, iOS, etc.)
   - Choose build mode (Debug, Profile, Release)
   - Optionally add build flavor and advanced options
4. Click **Start Build**
5. Monitor progress in the real-time log viewer

### Viewing Build History

1. Navigate to the **History** tab
2. View all past builds with:
   - Project name
   - Platform and mode
   - Build date and duration
   - Status and error messages
3. Click on a successful build to open its output folder

## 🏗️ Architecture

### Technology Stack

- **Frontend**: Flutter (Material Design 3)
- **State Management**: Provider
- **Local Storage**: SQLite (sqflite)
- **API Integration**: googleapis, googleapis_auth
- **Process Management**: process_run
- **File Operations**: path_provider, file_picker

### Project Structure

```
lib/
├── models/              # Data models
│   ├── flutter_project.dart
│   ├── build_history.dart
│   └── google_service_account.dart
├── services/            # Business logic
│   ├── database_service.dart
│   ├── project_service.dart
│   ├── build_service.dart
│   ├── flutter_sdk_service.dart
│   └── google_play_service.dart
├── providers/           # State management
│   ├── project_provider.dart
│   └── build_provider.dart
├── screens/             # UI screens
│   ├── home_screen.dart
│   └── add_project_screen.dart
├── widgets/             # Reusable widgets
│   ├── project_list_widget.dart
│   ├── build_config_widget.dart
│   └── build_history_widget.dart
├── utils/               # Utilities
│   ├── exceptions.dart
│   ├── logger.dart
│   └── error_handler.dart
├── constants/           # App constants
│   └── app_theme.dart
└── main.dart           # App entry point
```

## 🧪 Testing

Run tests:

```bash
flutter test
```

Run tests with coverage:

```bash
flutter test --coverage
```

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Romain Shindano** - *Initial work* - [RomainShindano](https://github.com/RomainShindano)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- All contributors who help improve Drop-Xide

## 📞 Support

If you encounter any issues or have questions:

- Open an issue on [GitHub](https://github.com/RomainShindano/Drop-Xide/issues)
- Check the [documentation](docs/)

## 🗺️ Roadmap

- [x] Project management
- [x] Build configuration
- [x] Build automation
- [x] Build history tracking
- [ ] Google Service Account integration
- [ ] Google Play Store publishing
- [ ] App Store Connect integration (iOS)
- [ ] CI/CD pipeline integration
- [ ] Build notifications
- [ ] Multi-language support

---

Made with ❤️ by the Drop-Xide team
