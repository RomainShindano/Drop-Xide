#!/bin/sh
#
# Xcode Cloud pre-xcodebuild hook for DropXide (macOS / SPM).
#
# Last check before xcodebuild. Anything missing here becomes an opaque
# "exit-code: 65", so fail with an explicit message instead.
#
set -euo pipefail

echo "=== DropXide Xcode Cloud: pre-xcodebuild (macOS / SPM) ==="

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
FLUTTER_PROJECT_PATH="${FLUTTER_PROJECT_PATH:-.}"
export PATH="$FLUTTER_HOME/bin:$PATH"
export FLUTTER_ROOT="$FLUTTER_HOME"

cd "$CI_PRIMARY_REPOSITORY_PATH/$FLUTTER_PROJECT_PATH"

EPHEMERAL_DIR="macos/Flutter/ephemeral"
GENERATED_XCCONFIG="$EPHEMERAL_DIR/Flutter-Generated.xcconfig"
PACKAGE_SWIFT="$EPHEMERAL_DIR/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"

mkdir -p "$EPHEMERAL_DIR"
for list in FlutterInputs FlutterOutputs; do
  path="$EPHEMERAL_DIR/$list.xcfilelist"
  [ -f "$path" ] || : > "$path"
done
[ -f "$EPHEMERAL_DIR/tripwire" ] || touch "$EPHEMERAL_DIR/tripwire"

if [ ! -f "$GENERATED_XCCONFIG" ] || [ ! -f "$PACKAGE_SWIFT" ]; then
  echo "Flutter generated files missing; regenerating"
  flutter pub get
  flutter build macos --config-only
fi

fail=0

if [ ! -f "$GENERATED_XCCONFIG" ]; then
  echo "ERROR: missing $GENERATED_XCCONFIG (Xcode cannot resolve FLUTTER_ROOT)"
  fail=1
elif ! grep -q '^FLUTTER_ROOT=' "$GENERATED_XCCONFIG"; then
  echo "ERROR: FLUTTER_ROOT not set in $GENERATED_XCCONFIG"
  cat "$GENERATED_XCCONFIG"
  fail=1
fi

if [ ! -f "$PACKAGE_SWIFT" ]; then
  echo "ERROR: missing $PACKAGE_SWIFT (plugin modules will not resolve)"
  fail=1
elif ! grep -q 'window_manager\|macos_ui\|shared_preferences_foundation\|sqflite_darwin' "$PACKAGE_SWIFT"; then
  echo "ERROR: $PACKAGE_SWIFT has no plugin dependencies:"
  cat "$PACKAGE_SWIFT"
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  echo "Failing now so the cause is visible instead of xcodebuild exit-code 65."
  exit 1
fi

rm -rf ~/Library/Caches/org.swift.swiftpm/artifacts 2>/dev/null || true

echo "=== Ready for xcodebuild ==="
echo "Action: ${CI_XCODEBUILD_ACTION:-<unset>}  Scheme: ${CI_XCODE_SCHEME:-<unset>}"
ls -la "$EPHEMERAL_DIR"
exit 0
