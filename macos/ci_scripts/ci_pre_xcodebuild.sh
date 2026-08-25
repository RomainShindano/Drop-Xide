#!/bin/sh
#
# Xcode Cloud pre-xcodebuild hook for DropXide (macOS / CocoaPods).
#
set -euo pipefail

echo "=== DropXide Xcode Cloud: pre-xcodebuild (macOS / CocoaPods) ==="

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
FLUTTER_PROJECT_PATH="${FLUTTER_PROJECT_PATH:-.}"
export PATH="$FLUTTER_HOME/bin:$PATH"

cd "$CI_PRIMARY_REPOSITORY_PATH/$FLUTTER_PROJECT_PATH"

flutter config --no-enable-swift-package-manager >/dev/null 2>&1 || true

GENERATED_XCCONFIG="macos/Flutter/ephemeral/Flutter-Generated.xcconfig"

if [ ! -f "$GENERATED_XCCONFIG" ]; then
  echo "=== Regenerating Flutter ephemeral files ==="
  flutter pub get
  flutter build macos --config-only
fi

if [ ! -f "$GENERATED_XCCONFIG" ]; then
  echo "ERROR: $GENERATED_XCCONFIG still missing before xcodebuild."
  exit 1
fi

if [ ! -d "macos/Pods/Pods.xcodeproj" ] || \
   [ ! -f "macos/Pods/Manifest.lock" ] || \
   ! diff -q "macos/Podfile.lock" "macos/Pods/Manifest.lock" >/dev/null 2>&1; then
  echo "=== CocoaPods out of sync; running pod install ==="
  cd macos
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  pod install
  cd ..
fi

if [ ! -d "macos/Pods/Pods.xcodeproj" ]; then
  echo "ERROR: macos/Pods/Pods.xcodeproj missing before xcodebuild."
  exit 1
fi

if [ ! -f "macos/Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig" ]; then
  echo "ERROR: Pods-Runner.release.xcconfig missing before xcodebuild."
  exit 1
fi

if ! grep -q '^FLUTTER_ROOT=' "$GENERATED_XCCONFIG"; then
  echo "ERROR: FLUTTER_ROOT not found in $GENERATED_XCCONFIG"
  cat "$GENERATED_XCCONFIG"
  exit 1
fi

echo "=== Flutter + CocoaPods ready for xcodebuild ==="
exit 0
