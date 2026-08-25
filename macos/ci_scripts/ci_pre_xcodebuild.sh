#!/bin/sh
#
# Xcode Cloud pre-xcodebuild hook for DropXide (macOS / SPM).
# Ensures ephemeral Flutter file lists exist before xcodebuild parses the project.
#
set -euo pipefail

echo "=== DropXide Xcode Cloud: pre-xcodebuild (macOS / SPM) ==="

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
FLUTTER_PROJECT_PATH="${FLUTTER_PROJECT_PATH:-.}"
export PATH="$FLUTTER_HOME/bin:$PATH"
export FLUTTER_ROOT="$FLUTTER_HOME"

cd "$CI_PRIMARY_REPOSITORY_PATH/$FLUTTER_PROJECT_PATH"

flutter config --enable-swift-package-manager >/dev/null 2>&1 || true

EPHEMERAL_DIR="macos/Flutter/ephemeral"
INPUTS_LIST="$EPHEMERAL_DIR/FlutterInputs.xcfilelist"
OUTPUTS_LIST="$EPHEMERAL_DIR/FlutterOutputs.xcfilelist"
GENERATED_XCCONFIG="$EPHEMERAL_DIR/Flutter-Generated.xcconfig"
PACKAGE_SWIFT="$EPHEMERAL_DIR/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"

# Must exist before xcodebuild loads the Flutter Assemble target
mkdir -p "$EPHEMERAL_DIR"
[ -f "$INPUTS_LIST" ] || : > "$INPUTS_LIST"
[ -f "$OUTPUTS_LIST" ] || : > "$OUTPUTS_LIST"
[ -f "$EPHEMERAL_DIR/tripwire" ] || touch "$EPHEMERAL_DIR/tripwire"

if [ ! -f "$GENERATED_XCCONFIG" ] || [ ! -f "$PACKAGE_SWIFT" ]; then
  echo "=== Regenerating Flutter ephemeral / SPM package ==="
  flutter pub get
  if flutter build macos -h 2>/dev/null | grep -q -- '--config-only'; then
    flutter build macos --config-only
  fi
  # Re-ensure lists after regenerate
  mkdir -p "$EPHEMERAL_DIR"
  [ -f "$INPUTS_LIST" ] || : > "$INPUTS_LIST"
  [ -f "$OUTPUTS_LIST" ] || : > "$OUTPUTS_LIST"
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

if [ ! -f "$INPUTS_LIST" ] || [ ! -f "$OUTPUTS_LIST" ]; then
  echo "ERROR: Flutter xcfilelists missing."
  exit 1
fi

rm -rf ~/Library/Caches/org.swift.swiftpm/artifacts 2>/dev/null || true

echo "=== Flutter SPM + xcfilelists ready for xcodebuild ==="
ls -la "$INPUTS_LIST" "$OUTPUTS_LIST"
exit 0
