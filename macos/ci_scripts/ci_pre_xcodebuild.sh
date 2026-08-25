#!/bin/sh
#
# Xcode Cloud pre-xcodebuild hook for DropXide (macOS only).
# Runs after SPM cache restore and before xcodebuild.
#
set -euo pipefail

echo "=== DropXide Xcode Cloud: pre-xcodebuild (macOS) ==="

# Clear stale SwiftPM caches
rm -rf ~/Library/Caches/org.swift.swiftpm/artifacts 2>/dev/null || true
rm -rf /Users/local/Library/Caches/org.swift.swiftpm/artifacts 2>/dev/null || true

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
FLUTTER_PROJECT_PATH="${FLUTTER_PROJECT_PATH:-.}"
export PATH="$FLUTTER_HOME/bin:$PATH"

cd "$CI_PRIMARY_REPOSITORY_PATH/$FLUTTER_PROJECT_PATH"

# Keep CocoaPods-only mode consistent with pubspec / post-clone
flutter config --no-enable-swift-package-manager >/dev/null 2>&1 || true

GENERATED_XCCONFIG="macos/Flutter/ephemeral/Flutter-Generated.xcconfig"

if [ ! -f "$GENERATED_XCCONFIG" ]; then
  echo "=== Flutter ephemeral files missing; regenerating ==="
  flutter pub get
  flutter build macos --config-only
fi

if [ ! -f "$GENERATED_XCCONFIG" ]; then
  echo "ERROR: $GENERATED_XCCONFIG still missing before xcodebuild."
  exit 1
fi

# Ensure CocoaPods is in sync (Pods is gitignored)
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
  echo "Framework 'Pods_Runner' not found will occur if the workspace cannot see Pods."
  exit 1
fi

if [ ! -f "macos/Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig" ]; then
  echo "ERROR: Pods-Runner.release.xcconfig missing before xcodebuild."
  exit 1
fi

# Verify FLUTTER_ROOT is set in generated xcconfig (required by macos_assemble.sh)
if ! grep -q '^FLUTTER_ROOT=' "$GENERATED_XCCONFIG"; then
  echo "ERROR: FLUTTER_ROOT not found in $GENERATED_XCCONFIG"
  cat "$GENERATED_XCCONFIG"
  exit 1
fi

echo "=== Flutter + CocoaPods ready for xcodebuild ==="
echo "=== Use workspace: macos/Runner.xcworkspace ==="
exit 0
