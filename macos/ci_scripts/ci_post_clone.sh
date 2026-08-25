#!/bin/sh
#
# Xcode Cloud post-clone hook for DropXide (macOS only, CocoaPods).
#
# Required Xcode Cloud environment variable:
#   FLUTTER_VERSION  e.g. stable or 3.24.0
#
# IMPORTANT: Build macos/Runner.xcworkspace (not .xcodeproj).
#
set -euo pipefail

echo "=== DropXide Xcode Cloud: post-clone (macOS / CocoaPods) ==="

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_PROJECT_PATH="${FLUTTER_PROJECT_PATH:-.}"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "=== Installing Flutter ($FLUTTER_VERSION) ==="
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"
flutter --version

# CocoaPods-only: do not use Flutter Swift Package Manager for plugins
flutter config --no-enable-swift-package-manager

cd "$CI_PRIMARY_REPOSITORY_PATH/$FLUTTER_PROJECT_PATH"

echo "=== Precache macOS artifacts ==="
flutter precache --macos

echo "=== flutter pub get ==="
flutter pub get

echo "=== Generate macOS Flutter ephemeral files (Flutter-Generated.xcconfig) ==="
flutter build macos --config-only

GENERATED_XCCONFIG="macos/Flutter/ephemeral/Flutter-Generated.xcconfig"
if [ ! -f "$GENERATED_XCCONFIG" ]; then
  echo "ERROR: Expected $GENERATED_XCCONFIG was not generated."
  ls -la macos/Flutter/ephemeral || true
  exit 1
fi

echo "=== Flutter-Generated.xcconfig ==="
cat "$GENERATED_XCCONFIG"

echo "=== pod install ==="
cd macos
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
rm -rf Pods .symlinks
pod install --repo-update
cd ..

if [ ! -d "macos/Pods/Pods.xcodeproj" ]; then
  echo "ERROR: macos/Pods/Pods.xcodeproj missing — cannot resolve plugin modules."
  exit 1
fi

for cfg in debug release profile; do
  xcconfig="macos/Pods/Target Support Files/Pods-Runner/Pods-Runner.${cfg}.xcconfig"
  if [ ! -f "$xcconfig" ]; then
    echo "ERROR: Missing $xcconfig"
    ls -la "macos/Pods/Target Support Files/Pods-Runner/" || true
    exit 1
  fi
  echo "=== $xcconfig ==="
  # Show which frameworks/modules CocoaPods will expose
  grep -E 'OTHER_LDFLAGS|HEADER_SEARCH|FRAMEWORK_SEARCH|OTHER_MODULE' "$xcconfig" || true
done

# Sanity: expected plugin pods should exist
for pod in window_manager macos_ui sqflite_darwin shared_preferences_foundation; do
  if [ ! -d "macos/Pods/$pod" ] && ! ls -d macos/Pods/$pod* >/dev/null 2>&1; then
    echo "WARNING: pod directory for $pod not found under macos/Pods (check Podfile.lock)"
  fi
done

echo "=== CocoaPods plugins ready (modules via Pods_Runner) ==="
echo "=== Reminder: use macos/Runner.xcworkspace ==="
echo "=== DropXide Xcode Cloud: post-clone complete ==="
exit 0
