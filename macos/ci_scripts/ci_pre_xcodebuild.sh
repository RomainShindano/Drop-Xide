#!/bin/sh
#
# Xcode Cloud pre-xcodebuild hook for DropXide (macOS / SPM).
#
set -euo pipefail

echo "=== DropXide Xcode Cloud: pre-xcodebuild (macOS / SPM) ==="

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
FLUTTER_PROJECT_PATH="${FLUTTER_PROJECT_PATH:-.}"
export PATH="$FLUTTER_HOME/bin:$PATH"

cd "$CI_PRIMARY_REPOSITORY_PATH/$FLUTTER_PROJECT_PATH"

flutter config --enable-swift-package-manager >/dev/null 2>&1 || true

GENERATED_XCCONFIG="macos/Flutter/ephemeral/Flutter-Generated.xcconfig"
PACKAGE_SWIFT="macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"

if [ ! -f "$GENERATED_XCCONFIG" ] || [ ! -f "$PACKAGE_SWIFT" ]; then
  echo "=== Regenerating Flutter ephemeral / SPM package ==="
  flutter pub get
fi

if [ ! -f "$GENERATED_XCCONFIG" ]; then
  echo "ERROR: $GENERATED_XCCONFIG still missing."
  exit 1
fi

if [ ! -f "$PACKAGE_SWIFT" ]; then
  echo "ERROR: $PACKAGE_SWIFT still missing."
  exit 1
fi

if ! grep -q 'window_manager\|macos_ui\|shared_preferences_foundation\|sqflite_darwin' "$PACKAGE_SWIFT"; then
  echo "ERROR: Package.swift still has no plugin dependencies:"
  cat "$PACKAGE_SWIFT"
  exit 1
fi

if ! grep -q '^FLUTTER_ROOT=' "$GENERATED_XCCONFIG"; then
  echo "ERROR: FLUTTER_ROOT not found in $GENERATED_XCCONFIG"
  cat "$GENERATED_XCCONFIG"
  exit 1
fi

# Clear stale SwiftPM caches that can break local package resolution
rm -rf ~/Library/Caches/org.swift.swiftpm/artifacts 2>/dev/null || true

echo "=== Flutter SPM package ready for xcodebuild ==="
exit 0
