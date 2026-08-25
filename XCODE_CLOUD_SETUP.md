# Xcode Cloud Setup Guide for Drop-Xide

## Quick Fix for Your Current Issue

The "Command PhaseScriptExecution failed" error happens because Xcode Cloud doesn't have Flutter installed by default. The scripts in `ios/ci_scripts/` will fix this automatically.

## Step-by-Step Setup

### 1. Configure Xcode Cloud Workflow

1. Open your project in Xcode
2. Go to **Product** → **Xcode Cloud** → **Create Workflow**
3. Select your iOS scheme
4. Click **Edit Workflow**

### 2. Add Environment Variable

In your workflow settings:
1. Click **Environment**
2. Add a new environment variable:
   - **Name**: `FLUTTER_VERSION`
   - **Value**: `stable` (or your Flutter version like `3.24.0`)

This tells the CI scripts which Flutter version to install.

### 3. Configure Code Signing

For TestFlight distribution:

1. **In Xcode**:
   - Select your project in the navigator
   - Select the iOS target (Runner)
   - Go to **Signing & Capabilities** tab
   - Check **Automatically manage signing**
   - Select your team

2. **In Xcode Cloud**:
   - Go to workflow **Settings**
   - Under **Code Signing**, select:
     - ✅ **Automatic code signing**
     - Your Apple Developer team
     - App Store Connect API key (if required)

### 4. Enable TestFlight Distribution

1. In your Xcode Cloud workflow
2. Go to **Post-Actions**
3. Add **TestFlight Internal Testing** action
4. Select your app and build configuration

### 5. Commit and Push

```bash
git add ios/ci_scripts/
git commit -m "Add Xcode Cloud scripts for Flutter iOS builds"
git push
```

Xcode Cloud will detect the scripts automatically!

## What the Scripts Do

### ci_post_clone.sh (Most Important!)
- ✅ Installs Flutter in Xcode Cloud environment
- ✅ Runs `flutter pub get`
- ✅ Generates iOS build configuration
- ✅ Runs `pod install` for CocoaPods dependencies

### ci_pre_xcodebuild.sh
- ✅ Clears stale caches
- ✅ Verifies Flutter files exist
- ✅ Regenerates if needed

### ci_post_xcodebuild.sh
- ✅ Logs build artifacts
- ✅ Can be customized for notifications

## Common Errors & Solutions

### ❌ "Command PhaseScriptExecution failed"
**Solution**: Add `FLUTTER_VERSION` environment variable (see step 2 above)

### ❌ "No such module 'Flutter'"
**Solution**: Scripts will fix this by generating ephemeral files

### ❌ "Pod install failed"
**Solution**: Check your Podfile is valid. The script runs `pod install` automatically.

### ❌ Code signing errors
**Solutions**:
1. Enable automatic signing in Xcode
2. Verify your Apple Developer account is connected
3. Check bundle ID matches your App Store Connect app
4. Ensure you have valid provisioning profiles

### ❌ "Can't distribute to TestFlight"
**Solutions**:
1. ✅ Enable automatic code signing
2. ✅ Set up post-action for TestFlight in workflow
3. ✅ Verify your app exists in App Store Connect
4. ✅ Check that bundle ID matches
5. ✅ Ensure you have the "App Manager" role or higher

## Verify It's Working

After pushing, check Xcode Cloud logs for:

```
✅ Installing Flutter...
✅ Flutter version: <your version>
✅ Running flutter pub get...
✅ Generating iOS build configuration...
✅ Post-Clone Script Completed
```

## Advanced Configuration

### Use Specific Flutter Version

Instead of `stable`, pin to a specific version:

```
FLUTTER_VERSION=3.24.0
```

### Add Custom Build Arguments

Edit `ci_post_clone.sh` and modify:

```bash
flutter build ios --config-only --no-codesign --dart-define=ENV=prod
```

### Skip Caching

If you have cache issues, clear more aggressively in `ci_pre_xcodebuild.sh`:

```bash
rm -rf ~/Library/Caches/* 2>/dev/null || true
```

## Testing Locally

Before pushing to Xcode Cloud, test the scripts locally:

```bash
cd ios/ci_scripts
./ci_post_clone.sh
./ci_pre_xcodebuild.sh
```

## Need Help?

Check Xcode Cloud build logs:
1. Open Xcode
2. Go to **Integrate** → **Xcode Cloud**
3. Select your failed build
4. Click **View Logs**
5. Look for errors in "Clone" and "Build" phases

## Next Steps After Setup

1. ✅ Commit and push the ci_scripts
2. ✅ Wait for Xcode Cloud to trigger a build
3. ✅ Check build logs
4. ✅ Fix any code signing issues if needed
5. ✅ Test your TestFlight build!

Your app should now build successfully on Xcode Cloud and distribute to TestFlight! 🎉
