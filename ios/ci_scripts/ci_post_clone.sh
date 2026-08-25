#!/bin/sh
#
# Xcode Cloud post-clone hook for Flutter iOS builds
#
# This script runs after Xcode Cloud clones your repository.
# It installs Flutter and generates the required ephemeral files.
#
# Required Xcode Cloud environment variable:
#   FLUTTER_VERSION  (e.g., "3.24.0" or "stable")
#
set -euo pipefail

echo "========================================="
echo "Xcode Cloud: Post-Clone Script (iOS)"
echo "========================================="

# Get Flutter version from environment or use stable
FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_HOME="$HOME/flutter"

echo "Flutter version: $FLUTTER_VERSION"

# Install Flutter if not already installed
if [ ! -d "$FLUTTER_HOME" ]; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$FLUTTER_HOME"
else
  echo "Flutter already installed at $FLUTTER_HOME"
fi

# Add Flutter to PATH
export PATH="$FLUTTER_HOME/bin:$PATH"

# Verify Flutter installation
echo "Verifying Flutter installation..."
flutter --version

# Navigate to project root
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Enable iOS
echo "Enabling iOS..."
flutter config --enable-ios

# Precache iOS artifacts
echo "Precaching iOS artifacts..."
flutter precache --ios

# Get dependencies
echo "Running flutter pub get..."
flutter pub get

# Generate iOS build files
echo "Generating iOS build configuration..."
flutter build ios --config-only --no-codesign

# Verify generated files
GENERATED_DIR="ios/Flutter/ephemeral"
if [ -d "$GENERATED_DIR" ]; then
  echo "✅ Generated files successfully at $GENERATED_DIR"
  ls -la "$GENERATED_DIR"
else
  echo "❌ ERROR: Failed to generate iOS Flutter files"
  exit 1
fi

# Run pod install if Podfile exists
if [ -f "ios/Podfile" ]; then
  echo "Running pod install..."
  cd ios
  pod install
  cd ..
else
  echo "No Podfile found, skipping pod install"
fi

echo "========================================="
echo "✅ Post-Clone Script Completed"
echo "========================================="

exit 0
