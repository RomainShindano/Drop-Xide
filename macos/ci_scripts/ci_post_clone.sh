#!/bin/sh
#
# Xcode Cloud post-clone hook for DropXide (macOS / Swift Package Manager).
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
export FLUTTER_ROOT="$FLUTTER_HOME"
flutter --version

flutter config --enable-swift-package-manager
flutter config --enable-macos-desktop

cd "$CI_PRIMARY_REPOSITORY_PATH/$FLUTTER_PROJECT_PATH"

EPHEMERAL_DIR="macos/Flutter/ephemeral"
INPUTS_LIST="$EPHEMERAL_DIR/FlutterInputs.xcfilelist"
OUTPUTS_LIST="$EPHEMERAL_DIR/FlutterOutputs.xcfilelist"
GENERATED_XCCONFIG="$EPHEMERAL_DIR/Flutter-Generated.xcconfig"
PACKAGE_DIR="$EPHEMERAL_DIR/Packages/FlutterGeneratedPluginSwiftPackage"
PACKAGE_SWIFT="$PACKAGE_DIR/Package.swift"

# Xcode's "Flutter Assemble" target references these file lists in the pbxproj.
# They are gitignored (ephemeral/) and must exist before xcodebuild parses the
# project, otherwise:
#   Unable to load contents of file list: '.../FlutterInputs.xcfilelist'
# Flutter itself creates empty lists when missing (see build_macos.dart).
echo "=== Creating ephemeral Flutter xcfilelists (required before xcodebuild) ==="
mkdir -p "$EPHEMERAL_DIR"
: > "$INPUTS_LIST"
: > "$OUTPUTS_LIST"
touch "$EPHEMERAL_DIR/tripwire"

echo "=== Precache macOS artifacts ==="
flutter precache --macos

echo "=== flutter pub get ==="
flutter pub get

# Prefer Flutter's config-only path when available (macOS CI).
if flutter build macos -h 2>/dev/null | grep -q -- '--config-only'; then
  echo "=== flutter build macos --config-only ==="
  flutter build macos --config-only
elif [ -x "$FLUTTER_ROOT/packages/flutter_tools/bin/macos_assemble.sh" ]; then
  echo "=== macos_assemble.sh prepare ==="
  (
    cd macos
    # Provide minimal env so prepare can write Generated.xcconfig / file lists
    export FLUTTER_APPLICATION_PATH="$CI_PRIMARY_REPOSITORY_PATH/$FLUTTER_PROJECT_PATH"
    export FLUTTER_TARGET=lib/main.dart
    export FLUTTER_BUILD_DIR=build
    export CONFIGURATION=Release
    export ACTION=build
    export SRCROOT="$PWD"
    "$FLUTTER_ROOT/packages/flutter_tools/bin/macos_assemble.sh" prepare || true
  )
fi

# Ensure file lists still exist (config-only / prepare may rewrite them)
mkdir -p "$EPHEMERAL_DIR"
[ -f "$INPUTS_LIST" ] || : > "$INPUTS_LIST"
[ -f "$OUTPUTS_LIST" ] || : > "$OUTPUTS_LIST"

if [ ! -f "$GENERATED_XCCONFIG" ]; then
  echo "ERROR: $GENERATED_XCCONFIG was not generated."
  ls -la "$EPHEMERAL_DIR" || true
  exit 1
fi

if [ ! -f "$PACKAGE_SWIFT" ]; then
  echo "ERROR: $PACKAGE_SWIFT was not generated."
  ls -la "$EPHEMERAL_DIR/Packages" || true
  exit 1
fi

echo "=== Flutter-Generated.xcconfig ==="
cat "$GENERATED_XCCONFIG"

echo "=== FlutterGeneratedPluginSwiftPackage/Package.swift ==="
cat "$PACKAGE_SWIFT"

if ! grep -q 'window_manager\|macos_ui\|shared_preferences_foundation\|sqflite_darwin' "$PACKAGE_SWIFT"; then
  echo "ERROR: Package.swift has no plugin dependencies."
  exit 1
fi

echo "=== Ephemeral file lists ==="
ls -la "$INPUTS_LIST" "$OUTPUTS_LIST"

echo "=== DropXide Xcode Cloud: post-clone complete (SPM) ==="
exit 0
