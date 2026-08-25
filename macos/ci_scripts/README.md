# Xcode Cloud scripts (macOS / CocoaPods)

DropXide uses **CocoaPods only** for macOS plugins (Swift Package Manager is disabled
and removed from the Xcode project).

| Script | When |
|--------|------|
| `ci_post_clone.sh` | Install Flutter, generate ephemeral files, `pod install` |
| `ci_pre_xcodebuild.sh` | Verify Flutter + Pods before xcodebuild |
| `ci_post_xcodebuild.sh` | Log archive paths |

## Required

- Env: `FLUTTER_VERSION` = `stable`
- Workflow builds **`macos/Runner.xcworkspace`**
