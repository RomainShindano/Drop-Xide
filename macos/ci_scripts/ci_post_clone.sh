#!/bin/sh
#
# Xcode Cloud post-clone hook for DropXide (macOS only).
#
# Runs after Xcode Cloud clones the repo, before xcodebuild.
# Without this script, Flutter ephemeral files and CocoaPods are missing,
# which causes: Command PhaseScriptExecution failed with a nonzero exit code
#
# Required Xcode Cloud environment variable:
#   FLUTTER_VERSION  e.g. stable or 3.24.0  (pin to the Flutter version you develop with)
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

cd "$CI_PRIMARY_REPOSITORY_PATH/$FLUTTER_PROJECT_PATH"

echo "=== Precache macOS artifacts ==="
flutter precache --macos

echo "=== flutter pub get ==="
flutter pub get

echo "=== Generate macOS Flutter ephemeral files ==="
# Creates:
#   macos/Flutter/ephemeral/Flutter-Generated.xcconfig  (sets FLUTTER_ROOT)
#   macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage
flutter build macos --config-only

GENERATED_XCCONFIG="macos/Flutter/ephemeral/Flutter-Generated.xcconfig"
PACKAGE_DIR="macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage"

if [ ! -f "$GENERATED_XCCONFIG" ]; then
  echo "ERROR: Expected $GENERATED_XCCONFIG was not generated."
  ls -la macos/Flutter/ephemeral || true
  exit 1
fi

if [ ! -d "$PACKAGE_DIR" ]; then
  echo "ERROR: Expected $PACKAGE_DIR was not generated."
  ls -la macos/Flutter/ephemeral || true
  exit 1
fi

echo "=== Flutter-Generated.xcconfig ==="
cat "$GENERATED_XCCONFIG"

# CocoaPods is required: Pods/ is gitignored. Without pod install,
# Xcode "Check Pods Manifest.lock" / "Embed Pods Frameworks" script phases fail
# with PhaseScriptExecution nonzero exit code.
echo "=== pod install ==="
cd macos
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
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

echo "=== DropXide Xcode Cloud: post-clone complete ==="
exit 0
