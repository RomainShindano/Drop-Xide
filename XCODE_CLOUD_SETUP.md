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
2. Open **Post-clone** first. `ci_post_clone.sh` runs `flutter build macos
   --config-only` and then an `xcodebuild` compile check with signing disabled,
   so Dart/Swift/plugin errors appear there with a readable message.
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

## "Build succeeded but I can't send it to TestFlight"

Symptom: the workflow's **TestFlight Internal Testing** post-action shows an
empty **Artifact** dropdown (highlighted red with `-`) and cannot be saved.

Cause: the workflow uses a **Build** action. A Build action only compiles —

```
xcodebuild build -scheme Runner ... CODE_SIGN_IDENTITY=- AD_HOC_CODE_SIGNING_ALLOWED=YES
```

Note `build` (not `archive`) and ad-hoc signing. It produces no archive, so the
TestFlight post-action has no artifact to distribute. A green build is expected
here; it just isn't a distributable one.

Fix: use an **Archive** action instead.

1. Xcode Cloud → workflow → **Edit Workflow**
2. Under **Actions**, click **+** and add **Archive**
   - Platform: **macOS**
   - Scheme: **Runner**
   - Deployment Preparation: **TestFlight and App Store**
     (or *TestFlight Internal Testing Only*)
3. Delete the old **Build - macOS** action (optional, but it doubles build time)
4. Open the **TestFlight Internal Testing** post-action — **Artifact** now
   offers the archive. Select it.
5. Set **Groups** to at least one internal tester group (it currently reads
   `None`, so nobody would receive the build)
6. **Save**, then start a new build

The Archive action builds the **Release** configuration, which uses
`Runner/Release.entitlements` (App Sandbox + hardened runtime) — the correct
configuration for TestFlight and the Mac App Store.

### Also required for macOS TestFlight

- App Store Connect must contain a **macOS** app record whose bundle ID is
  exactly `com.oxidetech.dropXide`
- The build number must increase for each upload. It comes from `pubspec.yaml`
  (`version: 1.0.0+1` → `CFBundleVersion = 1`), so bump the `+N` suffix before
  re-uploading the same version.

## Xcode Cloud checklist

1. Platform: **macOS**
2. Scheme: **Runner** (`macos/Runner.xcodeproj`)
3. Action: **Archive** (not Build) — required for TestFlight
4. Env: `FLUTTER_VERSION` = `stable` (or `3.47.1`)
5. Signing: Automatic, team `6C7TC4A89K`
6. Post-action: TestFlight Internal Testing, with an artifact **and** a group selected

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
