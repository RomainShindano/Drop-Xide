#!/bin/sh
#
# Xcode Cloud post-xcodebuild hook for Flutter iOS builds
#
# This script runs after a successful xcodebuild.
# Use it for post-processing, artifact management, or notifications.
#
set -euo pipefail

echo "========================================="
echo "Xcode Cloud: Post-Xcodebuild Script (iOS)"
echo "========================================="

cd "$CI_PRIMARY_REPOSITORY_PATH"

# Log build artifacts location
if [ -n "${CI_ARCHIVE_PATH:-}" ]; then
  echo "Archive path: $CI_ARCHIVE_PATH"
  echo "Archive contents:"
  ls -la "$CI_ARCHIVE_PATH" 2>/dev/null || true
fi

# Log product path
if [ -n "${CI_PRODUCT_PATH:-}" ]; then
  echo "Product path: $CI_PRODUCT_PATH"
  ls -la "$CI_PRODUCT_PATH" 2>/dev/null || true
fi

echo "========================================="
echo "✅ Post-Xcodebuild Script Completed"
echo "========================================="

exit 0
