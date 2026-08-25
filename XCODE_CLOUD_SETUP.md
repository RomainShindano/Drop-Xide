# Xcode Cloud Setup (macOS only)

DropXide is a **macOS desktop app**. Use the **macOS** workflow with
`macos/Runner.xcworkspace` — not an iOS scheme.

## What was broken

| Symptom | Cause |
|---------|--------|
| `Command PhaseScriptExecution failed with a nonzero exit code` | Flutter ephemeral files + CocoaPods `Pods/` are gitignored. Xcode still runs script phases that need them (`macos_assemble.sh`, Check Pods Manifest.lock). |
| Build succeeds but cannot distribute / TestFlight | Project-level `CODE_SIGN_IDENTITY = "-"` (ad-hoc) on Release blocked App Store signing. |
| `Unable to resolve module dependency: 'window_manager'` (and other plugins) | Swift Package Manager left in the Xcode project (`FlutterGeneratedPluginSwiftPackage`) while Flutter was configured for CocoaPods-only — the SPM package was empty, so every plugin import failed. |
| `Framework 'Pods_Runner' not found` | SPM hybrid left the project linking `Pods_Runner` without building it. |

## Fixes in this repo

1. **`macos/ci_scripts/`** — install Flutter, generate ephemeral files, run **`pod install`**
2. **Release / Profile signing** — removed ad-hoc `CODE_SIGN_IDENTITY = "-"`, enabled Hardened Runtime
3. **Bundle ID** — `com.oxidetech.dropXide` aligned in AppInfo
4. **Release entitlements** — App Sandbox + network / file / Flutter runtime entitlements for Mac App Store
5. **Removed `local_notifier`** — notifications use macOS `osascript`
6. **CocoaPods-only** — `enable-swift-package-manager: false`, static frameworks + modular headers
7. **Removed SPM from Xcode** — deleted `FlutterGeneratedPluginSwiftPackage` from `project.pbxproj` so plugin modules resolve via CocoaPods

## Xcode Cloud workflow checklist

1. **Platform**: macOS  
2. **Workspace**: `macos/Runner.xcworkspace` (**not** `Runner.xcodeproj`)  
3. **Scheme**: `Runner`  
4. **Archive configuration**: Release  
5. **Environment variable**: `FLUTTER_VERSION` = `stable`  
6. **Signing**: Automatic, team `6C7TC4A89K`  
7. **Post-action**: App Store Connect → TestFlight (Mac)

## Local recovery for module / Pods_Runner errors

```bash
flutter clean
flutter config --no-enable-swift-package-manager
flutter pub get
flutter build macos --config-only
cd macos
rm -rf Pods .symlinks
pod install --repo-update
cd ..
open macos/Runner.xcworkspace
```

In Xcode → Runner target → **Frameworks, Libraries, and Embedded Content**:
- Should list **Pods_Runner**
- Should **not** list `FlutterGeneratedPluginSwiftPackage`

Then build/archive from the **workspace**.

## App Store Connect

1. Create a **macOS** app (not iOS) with bundle ID `com.oxidetech.dropXide`
2. Ensure the same Apple team is linked to Xcode Cloud
3. For TestFlight Mac, distribution uses Mac App Store signing + App Sandbox

## Verify in build logs

Look for:

```
=== DropXide Xcode Cloud: post-clone (macOS) ===
=== pod install ===
=== DropXide Xcode Cloud: post-clone complete ===
=== Flutter + CocoaPods ready for xcodebuild ===
```

If PhaseScriptExecution still fails, expand the failed script phase in the log:

- **Run Script / Flutter Assemble** → `FLUTTER_ROOT` / ephemeral missing → check `ci_post_clone.sh`
- **Check Pods Manifest.lock** → `pod install` did not run or failed
- **Code Sign / Distribute** → signing / App Store Connect app / entitlements

## Local check before pushing

```bash
flutter pub get
flutter build macos --config-only
cd macos && pod install && cd ..
```

Then archive locally in Xcode (Product → Archive) and use Organizer → Distribute App → App Store Connect / TestFlight.
