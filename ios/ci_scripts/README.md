# Xcode Cloud Configuration for Flutter iOS

This directory contains scripts that Xcode Cloud runs automatically during iOS builds.

## Scripts

### ci_post_clone.sh
Runs immediately after Xcode Cloud clones your repository.
- Installs Flutter
- Runs `flutter pub get`
- Generates iOS build configuration
- Runs `pod install`

### ci_pre_xcodebuild.sh
Runs just before xcodebuild starts.
- Clears stale SwiftPM caches
- Verifies Flutter-generated files exist
- Regenerates if needed

### ci_post_xcodebuild.sh
Runs after successful xcodebuild.
- Logs artifact locations
- Can be used for post-processing

## Required Xcode Cloud Environment Variables

Set these in Xcode Cloud workflow settings:

- **FLUTTER_VERSION**: The Flutter version to use (e.g., "3.24.0" or "stable")
  - Recommended: Use the same version you develop with locally

## Common Issues & Solutions

### 1. "Command PhaseScriptExecution failed"
- **Cause**: Flutter not properly installed or scripts not executable
- **Solution**: Ensure `FLUTTER_VERSION` environment variable is set in Xcode Cloud

### 2. "Package resolution failed"
- **Cause**: Flutter-generated ephemeral files missing
- **Solution**: The ci_post_clone.sh script handles this automatically

### 3. Distribution/TestFlight issues
- **Cause**: Code signing configuration
- **Solution**: Configure automatic signing in Xcode Cloud workflow settings

## Setup Instructions

1. **In Xcode Cloud**:
   - Go to your workflow settings
   - Add environment variable: `FLUTTER_VERSION` = `stable` (or your version)
   - Enable automatic code signing
   - Select your App Store Connect team

2. **Code Signing**:
   - Use automatic signing (recommended)
   - Or manually configure signing certificates in Xcode Cloud

3. **Distribution**:
   - Enable "Distribute to TestFlight" in workflow settings
   - Select "TestFlight Internal Testing" for faster builds

## Troubleshooting

If builds fail, check Xcode Cloud logs for:
- Flutter installation success
- `flutter pub get` completion
- `pod install` success (if using CocoaPods)
- Code signing errors

For code signing issues:
- Verify your Apple Developer account is connected
- Check that provisioning profiles are valid
- Ensure bundle ID matches your App Store Connect app
