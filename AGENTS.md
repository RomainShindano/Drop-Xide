# AGENTS.md

## Cursor Cloud specific instructions

Drop-Xide is a single **Flutter desktop application** (build-automation / Google Play publishing tool). The only runnable target in this cloud VM is **Linux desktop**.

### Environment (already provisioned in the VM snapshot)
- Flutter SDK (stable, Dart ^3.13) is installed at `~/flutter` and is on `PATH` via `~/.bashrc`. In non-login shells that don't source `~/.bashrc`, call it explicitly: `~/flutter/bin/flutter`.
- Linux desktop build toolchain is installed (`clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, and — importantly — `libstdc++-14-dev`). `libstdc++-14-dev` is required: clang selects the GCC-14 toolchain, and without its `libstdc++.so` the C++ link step fails with `cannot find -lstdc++`.
- The update script runs `flutter pub get` on startup, so dependencies are already resolved.

### Standard commands (see README.md for the canonical list)
- Lint: `flutter analyze`
- Test: `flutter test`
- Build (dev): `flutter build linux --debug`  (release: `flutter build linux --release`)
- Run (dev): `export DISPLAY=:1 && flutter run -d linux`

### Non-obvious run/test caveats
- A VNC X server is already running on display **`:1`**. Always `export DISPLAY=:1` before `flutter run -d linux`; there is no other display.
- If a Linux build ever fails at the `cmake_install` step with a `/usr/local/...: Permission denied` error, it is a stale CMake cache. Run `flutter clean` (or `rm -rf build/`) and rebuild.
- **This app is macOS-first; several code paths are macOS-only and are NOT bugs in the environment.** On Linux the app builds and launches and the shell/sidebar renders, but data-backed screens do not function because of pre-existing app code:
  - `lib/main.dart` calls `macos_window_utils` unconditionally in `main()`; on Linux this throws `MissingPluginException` before `runApp()`, so the UI is blank unless that call is guarded (macOS-only).
  - `lib/utils/app_file_picker.dart` uses the `drop_xide/file_picker` `MethodChannel`, implemented only in the macOS Runner — the "Browse" folder picker does not work on Linux.
  - `lib/services/database_service.dart` uses `sqflite` directly, which has no Linux desktop implementation (would need `sqflite_common_ffi` + `databaseFactoryFfi`). Every DB-backed screen (Projects, Logs, Publish, Settings, etc.) therefore shows a "Retry" / empty error state on Linux.
  Do not treat these as environment breakage. Fixing them requires app code changes (out of scope for environment setup).
- Two test files are pre-existing failures unrelated to the environment: `test/widget_test.dart` (default counter template test vs. the real `MyApp` constructor) and `test/models/build_history_test.dart` (missing required `buildNumber` arg). The core model/util suites (`test/models/flutter_project_test.dart`, `test/utils/exceptions_test.dart`) pass.
