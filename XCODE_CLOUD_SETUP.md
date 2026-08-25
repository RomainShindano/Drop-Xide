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
