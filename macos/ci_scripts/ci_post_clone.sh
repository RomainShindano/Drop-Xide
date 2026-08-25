#!/bin/sh
#
# Xcode Cloud post-clone hook for DropXide (macOS / Swift Package Manager).
#
# Generates the Flutter files Xcode needs, then compiles once with code signing
# disabled to surface real Dart/Swift/plugin errors here — xcodebuild otherwise
# reports only "exit-code: 65" with no cause.
#
# Signing certificates are NOT available to post-clone scripts; Xcode Cloud only
# provides them to its own build/archive step. Any build run here must therefore
# pass CODE_SIGNING_ALLOWED=NO, or it fails with:
#   No signing certificate "Mac Development" found
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

echo "--- flutter pub get ---"
flutter pub get

# --config-only generates Flutter-Generated.xcconfig, the SPM plugin package,
# and the xcfilelists without invoking xcodebuild (so no signing needed).
echo "--- flutter build macos --config-only ---"
flutter build macos --config-only

echo "--- Verifying generated files ---"
for f in "$GENERATED_XCCONFIG" "$PACKAGE_SWIFT"; do
  if [ ! -f "$f" ]; then
    echo "ERROR: expected generated file missing: $f"
    find "$EPHEMERAL_DIR" -maxdepth 3 -print || true
    exit 1
  fi
done

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
  echo "Xcode would fail with 'Unable to resolve module dependency'."
  exit 1
fi

# Compile check without signing. Catches Swift/plugin/module errors while the
# log is still readable, and cannot fail for certificate reasons.
echo "--- Compile check (code signing disabled) ---"
if ! xcodebuild \
  -project macos/Runner.xcodeproj \
  -scheme Runner \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath build/ci-precheck \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build; then
  echo ""
  echo "=============================================="
  echo "COMPILE CHECK FAILED"
  echo "The Xcode error above is the real cause of the"
  echo "Xcode Cloud 'exit-code: 65' failure."
  echo "(Signing was disabled here, so this is NOT a"
  echo " certificate/provisioning problem.)"
  echo "=============================================="
  exit 1
fi

echo "=============================================="
echo "post-clone complete: compiles cleanly"
echo "=============================================="
exit 0
