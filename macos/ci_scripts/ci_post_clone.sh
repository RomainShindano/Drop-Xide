#!/bin/sh
#
# Xcode Cloud post-clone hook for DropXide (macOS only).
#
# Runs after Xcode Cloud clones the repo, before xcodebuild.
# Without this script, Flutter ephemeral files and CocoaPods are missing,
# which causes: Command PhaseScriptExecution failed / Framework Pods_Runner not found
#
# Required Xcode Cloud environment variable:
#   FLUTTER_VERSION  e.g. stable or 3.24.0  (pin to the Flutter version you develop with)
#
# IMPORTANT: Xcode Cloud workflow must build macos/Runner.xcworkspace (not .xcodeproj).
#
set -euo pipefail

echo "=== DropXide Xcode Cloud: post-clone (macOS) ==="

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_PROJECT_PATH="${FLUTTER_PROJECT_PATH:-.}"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"

# Install Flutter if needed
if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "=== Installing Flutter ($FLUTTER_VERSION) ==="
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"
flutter --version

# Match pubspec.yaml: CocoaPods-only for macOS plugins (avoids Pods_Runner hybrid SPM bug)
flutter config --no-enable-swift-package-manager

cd "$CI_PRIMARY_REPOSITORY_PATH/$FLUTTER_PROJECT_PATH"

echo "=== Precache macOS artifacts ==="
flutter precache --macos

echo "=== flutter pub get ==="
flutter pub get

echo "=== Generate macOS Flutter ephemeral files ==="
flutter build macos --config-only

GENERATED_XCCONFIG="macos/Flutter/ephemeral/Flutter-Generated.xcconfig"
PACKAGE_DIR="macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage"

if [ ! -f "$GENERATED_XCCONFIG" ]; then
  echo "ERROR: Expected $GENERATED_XCCONFIG was not generated."
  ls -la macos/Flutter/ephemeral || true
  exit 1
fi

# Package dir may still be generated because the Xcode project references it.
# It is OK if present as a stub while plugins come from CocoaPods.
if [ -d "$PACKAGE_DIR" ]; then
  echo "=== SPM package stub present at $PACKAGE_DIR ==="
fi

echo "=== Flutter-Generated.xcconfig ==="
cat "$GENERATED_XCCONFIG"

# CocoaPods is required: Pods/ is gitignored. Without pod install,
# the linker fails with: Framework 'Pods_Runner' not found
echo "=== pod install ==="
cd macos
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
rm -rf Pods
pod install --repo-update
cd ..

if [ ! -d "macos/Pods" ]; then
  echo "ERROR: macos/Pods was not created by pod install."
  exit 1
fi

if [ ! -f "macos/Pods/Manifest.lock" ]; then
  echo "ERROR: macos/Pods/Manifest.lock missing after pod install."
  exit 1
fi

if [ ! -d "macos/Pods/Pods.xcodeproj" ]; then
  echo "ERROR: macos/Pods/Pods.xcodeproj missing — Xcode cannot link Pods_Runner."
  exit 1
fi

for cfg in debug release profile; do
  xcconfig="macos/Pods/Target Support Files/Pods-Runner/Pods-Runner.${cfg}.xcconfig"
  if [ ! -f "$xcconfig" ]; then
    echo "ERROR: Missing $xcconfig (Pods_Runner will not link)."
    ls -la "macos/Pods/Target Support Files/Pods-Runner/" || true
    exit 1
  fi
done

echo "=== Pods-Runner ready (Pods_Runner will link via workspace) ==="
echo "=== Reminder: Xcode Cloud must use macos/Runner.xcworkspace ==="

echo "=== DropXide Xcode Cloud: post-clone complete ==="
exit 0
