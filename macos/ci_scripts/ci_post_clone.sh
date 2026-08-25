#!/bin/sh
#
# Xcode Cloud post-clone hook for DropXide (macOS / Swift Package Manager).
#
# All Flutter plugins used by this app ship Package.swift, so macOS uses SPM
# only (no CocoaPods). Xcode Cloud must have Xcode 15+ so Flutter can generate
# FlutterGeneratedPluginSwiftPackage with real plugin dependencies.
#
# Required environment variable:
#   FLUTTER_VERSION  e.g. stable or 3.47.1
#
set -euo pipefail

echo "=== DropXide Xcode Cloud: post-clone (macOS / SPM) ==="

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_PROJECT_PATH="${FLUTTER_PROJECT_PATH:-.}"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "=== Installing Flutter ($FLUTTER_VERSION) ==="
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"
flutter --version

# SPM is the supported path on Flutter 3.44+
flutter config --enable-swift-package-manager
flutter config --enable-macos-desktop

cd "$CI_PRIMARY_REPOSITORY_PATH/$FLUTTER_PROJECT_PATH"

echo "=== Precache macOS artifacts ==="
flutter precache --macos

echo "=== flutter pub get (generates FlutterGeneratedPluginSwiftPackage on macOS/Xcode) ==="
flutter pub get

GENERATED_XCCONFIG="macos/Flutter/ephemeral/Flutter-Generated.xcconfig"
PACKAGE_DIR="macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage"
PACKAGE_SWIFT="$PACKAGE_DIR/Package.swift"

# Ensure ephemeral Flutter config exists (pub get usually creates it on macOS)
if [ ! -f "$GENERATED_XCCONFIG" ]; then
  echo "=== Flutter-Generated.xcconfig missing; running macos assemble prepare ==="
  # macos_assemble prepare needs FLUTTER_ROOT; use flutter tool to materialize files
  flutter build bundle
  # On Xcode Cloud (macOS), also try the assemble helper if FLUTTER_ROOT is known
  if [ -x "$FLUTTER_HOME/packages/flutter_tools/bin/macos_assemble.sh" ]; then
    export FLUTTER_ROOT="$FLUTTER_HOME"
    (cd macos && "$FLUTTER_HOME/packages/flutter_tools/bin/macos_assemble.sh" prepare) || true
  fi
fi

if [ ! -f "$GENERATED_XCCONFIG" ]; then
  echo "ERROR: $GENERATED_XCCONFIG was not generated."
  ls -la macos/Flutter/ephemeral || true
  exit 1
fi

if [ ! -f "$PACKAGE_SWIFT" ]; then
  echo "ERROR: $PACKAGE_SWIFT was not generated."
  ls -la macos/Flutter/ephemeral/Packages || true
  exit 1
fi

echo "=== Flutter-Generated.xcconfig ==="
cat "$GENERATED_XCCONFIG"

echo "=== FlutterGeneratedPluginSwiftPackage/Package.swift ==="
cat "$PACKAGE_SWIFT"

# Package.swift must list plugin dependencies; an empty dependencies: [] means
# SPM feature was off or Xcode was unavailable when Flutter ran.
if ! grep -q 'window_manager\|macos_ui\|shared_preferences_foundation\|sqflite_darwin' "$PACKAGE_SWIFT"; then
  echo "ERROR: Package.swift has no plugin dependencies."
  echo "Unable to resolve module dependency errors will occur."
  echo "Ensure Flutter SPM is enabled and Xcode 15+ is available in this environment."
  exit 1
fi

# CocoaPods must NOT be required
if [ -f macos/Podfile ]; then
  echo "WARNING: macos/Podfile exists; this project is SPM-only. Consider removing it."
fi

echo "=== DropXide Xcode Cloud: post-clone complete (SPM) ==="
exit 0
