# Xcode Cloud scripts (macOS / Swift Package Manager)

DropXide uses **Swift Package Manager only** for macOS plugins (no CocoaPods).

| Script | When |
|--------|------|
| `ci_post_clone.sh` | Install Flutter, `flutter pub get`, verify SPM `Package.swift` has plugins |
| `ci_pre_xcodebuild.sh` | Re-verify SPM package before xcodebuild |
| `ci_post_xcodebuild.sh` | Log archive paths |

## Required

- Env: `FLUTTER_VERSION` = `stable` (or pin, e.g. `3.47.1`)
- Xcode 15+ (required for Flutter SPM)
- Scheme: `Runner` in `macos/Runner.xcodeproj`
