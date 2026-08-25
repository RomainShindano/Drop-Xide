# Xcode Cloud scripts (macOS)

DropXide is a **macOS-only** Flutter app. These scripts live at `macos/ci_scripts/`
so Xcode Cloud runs them automatically when building `macos/Runner.xcworkspace`.

| Script | When |
|--------|------|
| `ci_post_clone.sh` | After clone — installs Flutter, generates ephemeral files, runs `pod install` |
| `ci_pre_xcodebuild.sh` | Before xcodebuild — verifies Flutter + Pods, clears stale SwiftPM caches |
| `ci_post_xcodebuild.sh` | After xcodebuild — logs archive paths |

## Required environment variable

In the Xcode Cloud workflow → **Environment**:

- `FLUTTER_VERSION` = `stable` (or pin, e.g. `3.24.0`)

## Why builds fail without these scripts

1. `macos/Flutter/ephemeral/` is gitignored → `macos_assemble.sh` / SwiftPM package missing → **PhaseScriptExecution failed**
2. `macos/Pods/` is gitignored → CocoaPods “Check Pods Manifest.lock” fails → **PhaseScriptExecution failed**
