#!/bin/sh
#
# Xcode Cloud pre-xcodebuild hook for Flutter iOS builds
#
# This script runs just before xcodebuild starts.
# It ensures Flutter-generated files are present and clears stale caches.
#
set -euo pipefail

echo "========================================="
echo "Xcode Cloud: Pre-Xcodebuild Script (iOS)"
echo "========================================="

# Add Flutter to PATH
FLUTTER_HOME="$HOME/flutter"
export PATH="$FLUTTER_HOME/bin:$PATH"

# Clear SwiftPM caches (prevents resolution issues)
echo "Clearing SwiftPM caches..."
rm -rf ~/Library/Caches/org.swift.swiftpm 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/DerivedData 2>/dev/null || true

# Navigate to project root
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Regenerate if needed
GENERATED_DIR="ios/Flutter/ephemeral"
if [ ! -d "$GENERATED_DIR" ]; then
  echo "Regenerating iOS Flutter files..."
  flutter pub get
  flutter build ios --config-only --no-codesign
fi

# Verify files exist
if [ ! -d "$GENERATED_DIR" ]; then
  echo "❌ ERROR: iOS Flutter ephemeral files missing"
  exit 1
fi

echo "✅ iOS Flutter files verified"

echo "========================================="
echo "✅ Pre-Xcodebuild Script Completed"
echo "========================================="

exit 0
