#!/bin/sh
#
# Xcode Cloud pre-xcodebuild hook for DropXide (macOS).
# Runs after SPM cache restore and before xcodebuild package resolution/build.
#
set -euo pipefail

echo "=== DropXide Xcode Cloud: pre-xcodebuild ==="

# Clear stale SwiftPM caches that can break resolution on Xcode Cloud.
rm -rf ~/Library/Caches/org.swift.swiftpm/artifacts || true
rm -rf /Users/local/Library/Caches/org.swift.swiftpm/artifacts || true

FLUTTER_PROJECT_PATH="${FLUTTER_PROJECT_PATH:-.}"
cd "$CI_PRIMARY_REPOSITORY_PATH/$FLUTTER_PROJECT_PATH"

PACKAGE_DIR="macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage"
if [ ! -d "$PACKAGE_DIR" ]; then
  echo "=== Package missing; regenerating with Flutter ==="
  export PATH="$HOME/flutter/bin:$PATH"
  flutter pub get
  flutter build macos --config-only
fi

if [ ! -d "$PACKAGE_DIR" ]; then
  echo "ERROR: $PACKAGE_DIR still missing before xcodebuild."
  exit 1
fi

echo "=== Package present; continuing to xcodebuild ==="
exit 0
