#!/bin/sh
#
# Xcode Cloud post-clone hook for DropXide (macOS / Swift Package Manager).
#
# Strategy: run a COMPLETE `flutter build macos` here, before Xcode Cloud runs
# its own xcodebuild. Flutter prints readable errors; Xcode Cloud only reports
# "Command exited with non-zero exit-code: 65". If something is wrong, this
# script fails with the real reason instead of an opaque xcodebuild failure.
#
# Required environment variable:
#   FLUTTER_VERSION  e.g. stable or 3.47.1
#
set -euo pipefail

echo "=============================================="
echo "DropXide Xcode Cloud: post-clone (macOS / SPM)"
echo "=============================================="

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_PROJECT_PATH="${FLUTTER_PROJECT_PATH:-.}"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"

echo "--- Environment ---"
echo "FLUTTER_VERSION=$FLUTTER_VERSION"
echo "CI_XCODEBUILD_ACTION=${CI_XCODEBUILD_ACTION:-<unset>}"
echo "CI_XCODE_SCHEME=${CI_XCODE_SCHEME:-<unset>}"
echo "CI_WORKFLOW=${CI_WORKFLOW:-<unset>}"
sw_vers || true
xcodebuild -version || true

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "--- Installing Flutter ($FLUTTER_VERSION) ---"
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"
export FLUTTER_ROOT="$FLUTTER_HOME"
flutter --version

flutter config --enable-swift-package-manager
flutter config --enable-macos-desktop

cd "$CI_PRIMARY_REPOSITORY_PATH/$FLUTTER_PROJECT_PATH"

EPHEMERAL_DIR="macos/Flutter/ephemeral"
GENERATED_XCCONFIG="$EPHEMERAL_DIR/Flutter-Generated.xcconfig"
PACKAGE_SWIFT="$EPHEMERAL_DIR/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"

echo "--- flutter doctor ---"
flutter doctor -v || true

echo "--- flutter pub get ---"
flutter pub get

# A full build materializes everything Xcode needs (Flutter-Generated.xcconfig,
# the SPM plugin package, xcfilelists with real contents) and surfaces any
# Dart/Swift/plugin error with a readable message.
echo "--- flutter build macos --release (full build to surface real errors) ---"
if ! flutter build macos --release --verbose; then
  echo ""
  echo "=============================================="
  echo "FLUTTER BUILD FAILED"
  echo "This is the real cause of the Xcode Cloud"
  echo "'exit-code: 65' failure. See the Flutter error above."
  echo "=============================================="
  exit 1
fi

echo "--- Verifying generated files ---"
for f in "$GENERATED_XCCONFIG" "$PACKAGE_SWIFT"; do
  if [ ! -f "$f" ]; then
    echo "ERROR: expected generated file missing: $f"
    find "$EPHEMERAL_DIR" -maxdepth 3 -print || true
    exit 1
  fi
done

# Xcode's Flutter Assemble phase reads these; empty is valid, missing is fatal.
for list in FlutterInputs FlutterOutputs; do
  path="$EPHEMERAL_DIR/$list.xcfilelist"
  [ -f "$path" ] || : > "$path"
done
[ -f "$EPHEMERAL_DIR/tripwire" ] || touch "$EPHEMERAL_DIR/tripwire"

echo "--- Flutter-Generated.xcconfig ---"
cat "$GENERATED_XCCONFIG"

echo "--- FlutterGeneratedPluginSwiftPackage/Package.swift ---"
cat "$PACKAGE_SWIFT"

if ! grep -q 'window_manager\|macos_ui\|shared_preferences_foundation\|sqflite_darwin' "$PACKAGE_SWIFT"; then
  echo "ERROR: Package.swift lists no plugin dependencies."
  echo "Xcode will fail with 'Unable to resolve module dependency'."
  exit 1
fi

echo "--- Built app ---"
ls -la build/macos/Build/Products/Release/ 2>/dev/null || true

echo "=============================================="
echo "post-clone complete: Flutter build succeeded"
echo "=============================================="
exit 0
