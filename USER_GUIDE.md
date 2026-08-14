# Drop-Xide User Guide

## Table of Contents
1. [Getting Started](#getting-started)
2. [Managing Projects](#managing-projects)
3. [Building Projects](#building-projects)
4. [Viewing Build History](#viewing-build-history)
5. [Advanced Features](#advanced-features)
6. [Troubleshooting](#troubleshooting)

## Getting Started

### First Launch

When you first launch Drop-Xide, you'll see the home screen with four main tabs:
- **Projects**: Manage your Flutter projects
- **Build**: Configure and start builds
- **History**: View past builds
- **Settings**: Configure app settings (coming soon)

### System Requirements

Ensure you have:
- Flutter SDK installed and in your PATH
- Git installed
- Platform-specific build tools (Android SDK, Xcode, etc.)

## Managing Projects

### Adding a Project

1. Click the **+** button in the Projects tab
2. Click **Browse** to open the file picker
3. Navigate to your Flutter project's root directory
4. Select the directory
5. Click **Add Project**

The app will validate that:
- A `pubspec.yaml` file exists
- The Flutter dependency is present
- The directory structure is valid

### Viewing Projects

All your projects are displayed as cards showing:
- Project name
- Project path
- Description (if available)
- Date added
- Last build date (if built)

### Selecting a Project

Click on any project card to select it. The selected project will be highlighted and used for building.

### Deleting a Project

1. Click the **trash icon** on the project card
2. Confirm the deletion in the dialog
3. The project will be removed from the list (files remain on disk)

## Building Projects

### Basic Build

1. Select a project from the Projects tab
2. Go to the **Build** tab
3. Select your target platform:
   - Android
   - iOS
   - Web
   - Linux
   - macOS
   - Windows
4. Choose build mode:
   - **Debug**: For development and debugging
   - **Profile**: For performance profiling
   - **Release**: For production deployment
5. Click **Start Build**

### Advanced Build Options

#### Build Flavors

Add a custom flavor (e.g., "dev", "staging", "production"):
1. Enter the flavor name in the text field
2. Ensure your Flutter project is configured for flavors

#### Code Obfuscation

Enable to obfuscate your Dart code:
- Toggle the **Obfuscate** switch
- Only effective in Release mode

#### Split Debug Info

Store debug information separately:
- Toggle the **Split Debug Info** switch
- Useful for app size optimization

### Monitoring Builds

During a build:
- Watch real-time logs in the log viewer
- See build progress
- View any errors or warnings

### Build Output Location

Builds are automatically organized:
```
~/Dropxide/
└── ProjectName/
    └── 2024-08-14_15-30-45/
        └── [build artifacts]
```

Each build is stored in a timestamped folder for easy identification.

## Viewing Build History

### History Tab

The History tab shows all past builds with:
- Project name
- Platform and mode
- Build date and time
- Duration
- Status badge (Success, Failed, Running, etc.)
- Output path
- Error messages (for failed builds)

### Build Status

- **Success** (Green): Build completed successfully
- **Failed** (Red): Build failed (see error message)
- **Running** (Blue): Build in progress
- **Cancelled** (Orange): Build was cancelled
- **Pending** (Grey): Build queued

### Opening Build Output

For successful builds:
1. Click on the build card
2. The output folder will open in your file manager

## Advanced Features

### Multiple Projects

You can manage unlimited Flutter projects:
- Add as many projects as needed
- Switch between them instantly
- Each maintains its own build history

### Concurrent Builds

(Note: Currently, only one build at a time is supported. Concurrent builds coming soon.)

### Build History Management

Build history is stored locally in SQLite:
- Persistent across app restarts
- Fast querying and filtering
- Automatic cleanup options (coming soon)

## Troubleshooting

### "Flutter SDK not found"

**Solution:**
1. Ensure Flutter is installed
2. Add Flutter to your system PATH
3. Restart Drop-Xide
4. Run `flutter doctor` to verify installation

### "Not a valid Flutter project"

**Solution:**
1. Ensure the directory contains `pubspec.yaml`
2. Verify Flutter dependency in `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
   ```
3. Run `flutter pub get` in the project directory

### Build Fails

**Solution:**
1. Check the error message in build history
2. Review the build logs
3. Ensure all dependencies are installed
4. Try building from command line to isolate issues:
   ```bash
   cd /path/to/project
   flutter build [platform] --release
   ```

### "Permission denied" errors

**Solution:**
1. Ensure Drop-Xide has write permissions to:
   - `~/Dropxide/` directory
   - Your Flutter project directories
2. On Linux/macOS, check file permissions
3. On Windows, run as administrator if needed

### Build output not found

**Solution:**
1. Check if build completed successfully
2. Verify `~/Dropxide/` directory exists
3. Check disk space availability

## Tips and Best Practices

### Project Organization

- Keep projects organized in a dedicated directory
- Use descriptive project names
- Add meaningful descriptions in `pubspec.yaml`

### Build Management

- Use Debug mode during development
- Profile mode for performance testing
- Release mode for production
- Clean old builds periodically to save disk space

### Performance

- Close other resource-intensive applications during builds
- Ensure adequate disk space (at least 2GB free)
- Use SSD for faster build times

## Keyboard Shortcuts

(Coming soon)

## Getting Help

If you need help:
1. Check this user guide
2. Visit the [GitHub repository](https://github.com/RomainShindano/Drop-Xide)
3. Open an issue for bugs or questions
4. Read the [Contributing Guide](CONTRIBUTING.md) to contribute

## Updates

Drop-Xide will notify you of updates (feature coming soon). You can also:
1. Check the [Releases page](https://github.com/RomainShindano/Drop-Xide/releases)
2. Pull the latest changes if building from source

---

Thank you for using Drop-Xide! 🚀
