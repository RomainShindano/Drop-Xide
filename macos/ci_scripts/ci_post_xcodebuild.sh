#!/bin/sh
#
# Xcode Cloud post-xcodebuild hook for DropXide (macOS only).
#
set -euo pipefail

echo "=== DropXide Xcode Cloud: post-xcodebuild (macOS) ==="

if [ -n "${CI_ARCHIVE_PATH:-}" ]; then
  echo "Archive: $CI_ARCHIVE_PATH"
  ls -la "$CI_ARCHIVE_PATH" 2>/dev/null || true
fi

if [ -n "${CI_PRODUCT:-}" ]; then
  echo "Product: $CI_PRODUCT"
fi

if [ -n "${CI_APP_STORE_SIGNED_APP_PATH:-}" ]; then
  echo "App Store signed app: $CI_APP_STORE_SIGNED_APP_PATH"
fi

echo "=== DropXide Xcode Cloud: post-xcodebuild complete ==="
exit 0
