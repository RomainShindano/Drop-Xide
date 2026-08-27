# Xcode Cloud Setup (macOS / Swift Package Manager)

DropXide is a **macOS desktop app**. Native plugins are linked with
**Swift Package Manager only** (no CocoaPods).

## What was broken

| Symptom | Cause |
|---------|--------|
| `Unable to resolve module dependency: 'window_manager'` (and other plugins) | CocoaPods search paths pointed at DerivedData products that were never built before the module scanner ran. |
| `Framework 'Pods_Runner' not found` | Hybrid SPM + CocoaPods left the project linking a framework that wasn't produced. |
| Empty `FlutterGeneratedPluginSwiftPackage` | SPM disabled in `pubspec.yaml` while the Xcode project still expected SPM modules. |

## Fix in this repo

1. Re-enabled Flutter Swift Package Manager (default on Flutter 3.44+)
2. Restored `FlutterGeneratedPluginSwiftPackage` in `macos/Runner.xcodeproj`
3. Removed CocoaPods from the macOS project (`Podfile`, `Pods_Runner`, `[CP]` script phases)
4. Flutter xcconfigs only include `ephemeral/Flutter-Generated.xcconfig`
5. CI scripts verify `Package.swift` contains real plugin dependencies
6. CI creates empty `FlutterInputs.xcfilelist` / `FlutterOutputs.xcfilelist` before
   xcodebuild (fixes `Unable to load contents of file list` on Flutter Assemble)

## Reading `exit-code: 65`

`xcodebuild ... exited with non-zero exit-code: 65` is a **generic** build failure.
It never contains the cause. The real error is earlier in the log.

To find it in Xcode Cloud:

1. Open the failed build → **Logs**
2. Open **Post-clone** first. `ci_post_clone.sh` now runs a full
   `flutter build macos --release --verbose`, so a Flutter/Dart/plugin error
   appears there with a readable message.
3. If post-clone passed, open the **Build** / **Archive** step and expand the
   first red row (not the summary). Useful search terms:
   - `error:`
   - `No profiles for`
   - `Unable to resolve module`
   - `Command PhaseScriptExecution failed`

## Signing errors

```
No signing certificate "Mac Development" found: No "Mac Development" signing
certificate matching team ID "6C7TC4A89K" with a private key was found.
```

Signing certificates are only available to Xcode Cloud's own build/archive step.
They are **not** available inside `ci_post_clone.sh` / `ci_pre_xcodebuild.sh`, so
any `xcodebuild` or `flutter build macos` run from a CI script must disable
signing:

```bash
xcodebuild ... CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""
```

If the same error appears in the **real** build step, then Xcode Cloud has no
usable certificate for team `6C7TC4A89K`. Fix it in the workflow:

1. Xcode Cloud → workflow → **Archive** (or Build) action
2. Set **Code Signing** to *Xcode Cloud managed* / automatic
3. Confirm the Apple Developer team is connected and has a macOS distribution
   certificate

## Build action vs Archive action

The command

```
xcodebuild build -scheme Runner ... CODE_SIGN_IDENTITY=- AD_HOC_CODE_SIGNING_ALLOWED=YES
```

is Xcode Cloud's **Build** action with ad-hoc signing. It compiles only and
**cannot produce a TestFlight build**. For TestFlight you need an **Archive**
action in the workflow (with your team's signing), plus a TestFlight post-action.

If the TestFlight post-action's **Artifact** dropdown is empty, this is why:
a Build action produces no archive to distribute.

## App Store Connect upload rejections

### ITMS-90242 — missing `LSApplicationCategoryType`

Every Mac App Store upload must declare a category. The value comes from
`PRODUCT_APP_CATEGORY` in `macos/Runner/Configs/AppInfo.xcconfig` and is
referenced by `LSApplicationCategoryType` in `Runner/Info.plist`. DropXide uses
`public.app-category.developer-tools`.

### Other upload requirements

- App Store Connect needs a **macOS** app record with bundle ID exactly
  `com.oxidetech.dropXide`
- `CFBundleVersion` must increase per upload. It comes from `pubspec.yaml`
  (`version: 1.0.0+1` → build `1`), so bump the `+N` suffix before re-uploading.
- Release builds should not request Hardened Runtime exceptions they don't need.
  Flutter release builds are AOT-compiled, so `com.apple.security.cs.allow-jit`
  and `allow-unsigned-executable-memory` are unnecessary and invite review
  questions. They belong only in `DebugProfile.entitlements`.

## App Sandbox and user-selected paths

Anything the user chooses through the open panel (project folders, the Flutter
SDK, service-account JSON) is reachable under App Sandbox, but **only until the
app quits** — unless a security-scoped bookmark is stored.

`Runner/MainFlutterWindow.swift` saves a bookmark for every pick and reopens
them on launch via the `restoreAccess` channel method, which `main()` awaits
before any provider reads a path. Without that step, saved projects and a
located SDK become unreadable after a relaunch even though the paths look valid.

Auto-detection still cannot scan system locations such as `/opt/homebrew`;
sandbox denies those outright. Use **Locate…** in Settings so the SDK arrives
through the open panel and gets a bookmark.

## App Sandbox limits on running builds

TestFlight and the Mac App Store require **App Sandbox**
(`com.apple.security.app-sandbox`), enabled in `Runner/Release.entitlements`.

Sandboxing does **not** stop DropXide from spawning `git`, `flutter`, `open` or
`osascript`. A sandboxed process may exec other binaries; the child simply
inherits the same sandbox. So short, contained operations — reading a project,
listing branches, revealing a file — work once the relevant folder has been
granted through the open panel.

Full builds are the problem. A Flutter build writes far outside the folders the
user picked:

| Toolchain path | Purpose |
|---|---|
| `~/.pub-cache` | Dart package cache |
| `<sdk>/bin/cache` | Flutter's own engine artifacts |
| `~/.gradle`, `~/.android` | Android builds |
| `~/Library/Developer/Xcode/DerivedData` | iOS/macOS builds |
| `$TMPDIR`, `/tmp` | intermediates |

None of those are covered by `files.user-selected`, and no entitlement grants
them. Expect builds to fail partway even though the app launches and detects
projects correctly.

To ship DropXide as a full build tool, distribute it **outside** the App Store:

1. Archive with **Developer ID Application** signing
2. Notarize (`xcrun notarytool submit`), then staple, and ship a `.dmg`/`.zip`
3. Set `com.apple.security.app-sandbox` to `false` in `Release.entitlements` —
   sandbox is not required outside the App Store
4. Keep **Hardened Runtime** enabled; notarization requires it

Xcode Cloud can still build and notarize this; it produces a Developer ID
archive instead of using a TestFlight post-action.

## Xcode Cloud checklist

1. Platform: **macOS**
2. Scheme: **Runner** (`macos/Runner.xcodeproj` / workspace)
3. Env: `FLUTTER_VERSION` = `stable` (or `3.47.1`)
4. Signing: Automatic, team `6C7TC4A89K`
5. Post-action: TestFlight (Mac)

## Local recovery

```bash
flutter clean
flutter config --enable-swift-package-manager
flutter pub get
# On a Mac with Xcode 15+, Package.swift should list plugins:
cat macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift
open macos/Runner.xcworkspace
```

In Xcode → Runner → Frameworks:

- **FlutterGeneratedPluginSwiftPackage** present
- **Pods_Runner** absent

## Verify in Xcode Cloud logs

```
=== DropXide Xcode Cloud: post-clone (macOS / SPM) ===
=== FlutterGeneratedPluginSwiftPackage/Package.swift ===
... window_manager / macos_ui / ...
=== DropXide Xcode Cloud: post-clone complete (SPM) ===
```

If `Package.swift` shows empty `dependencies: []`, Flutter did not see Xcode 15+ / SPM was disabled — the build will fail the CI script before xcodebuild.
