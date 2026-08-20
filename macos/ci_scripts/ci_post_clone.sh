#!/bin/sh
#
# Xcode Cloud post-clone hook for DropXide (macOS).
#
# Xcode Cloud clones the repo and runs xcodebuild against macos/Runner.xcworkspace,
# but Flutter's ephemeral Swift package
# (macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage) is
# gitignored and missing until Flutter generates it. Without this script,
# package resolution fails with:
#   the package at '.../FlutterGeneratedPluginSwiftPackage' doesn't exist
#
# Xcode Cloud runs this automatically when present at:
#   macos/ci_scripts/ci_post_clone.sh
#
# Required Xcode Cloud environment variable:
#   FLUTTER_VERSION  e.g. 3.47.1  (pin to the Flutter version you develop with)
#
set -euo pipefail

echo "=== DropXide Xcode Cloud: post-clone ==="

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.1}"
FLUTTER_PROJECT_PATH="${FLUTTER_PROJECT_PATH:-.}"

# Install pinned Flutter
if [ ! -x "$HOME/flutter/bin/flutter" ]; then
  echo "=== Installing Flutter $FLUTTER_VERSION ==="
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"
flutter --version

cd "$CI_PRIMARY_REPOSITORY_PATH/$FLUTTER_PROJECT_PATH"

echo "=== Precache macOS artifacts ==="
flutter precache --macos

echo "=== flutter pub get ==="
flutter pub get

echo "=== Generate macOS Flutter / SwiftPM ephemeral packages ==="
# Creates macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage
# which Xcode Cloud must resolve before xcodebuild.
flutter build macos --config-only

PACKAGE_DIR="macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage"
if [ ! -d "$PACKAGE_DIR" ]; then
  echo "ERROR: Expected $PACKAGE_DIR was not generated."
  ls -la macos/Flutter/ephemeral || true
  exit 1
fi

echo "=== Generated package OK: $PACKAGE_DIR ==="
ls -la "$PACKAGE_DIR"

echo "=== DropXide Xcode Cloud: post-clone complete ==="
exit 0
