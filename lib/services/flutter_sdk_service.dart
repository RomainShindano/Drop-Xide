import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Locates the Flutter SDK on the host machine.
///
/// A GUI app launched from Finder or the Dock does not inherit the shell's
/// `PATH`, so `which flutter` alone fails even when Flutter works in Terminal.
/// Detection therefore tries, in order:
///
/// 1. a path the user chose explicitly (persisted),
/// 2. the user's login shell, which applies their real `PATH`,
/// 3. well-known install locations (Homebrew, fvm, asdf, mise, puro, manual).
class FlutterSdkService {
  static const _prefsKey = 'flutter_sdk_path';
  static const _lookupTimeout = Duration(seconds: 20);

  String? _flutterPath;
  String? _flutterVersion;
  String? _sdkRoot;
  bool _isManual = false;
  List<String> _searchedPaths = const [];

  String? get flutterPath => _flutterPath;
  String? get flutterVersion => _flutterVersion;
  String? get sdkRoot => _sdkRoot;
  bool get isFlutterAvailable => _flutterPath != null;

  Future<bool> detectFlutterSdk() async {
    final searched = <String>[];

    final manual = await _savedPath();
    if (manual != null) {
      final binary = _resolveBinary(manual);
      searched.add(manual);
      if (binary != null && await _adopt(binary, isManual: true)) {
        _searchedPaths = searched;
        return true;
      }
    }

    final fromShell = await _resolveViaLoginShell();
    if (fromShell != null) {
      searched.add(fromShell);
      if (await _adopt(fromShell, isManual: false)) {
        _searchedPaths = searched;
        return true;
      }
    }

    for (final candidate in _wellKnownBinaries()) {
      searched.add(candidate);
      if (File(candidate).existsSync() &&
          await _adopt(candidate, isManual: false)) {
        _searchedPaths = searched;
        return true;
      }
    }

    _flutterPath = null;
    _flutterVersion = null;
    _sdkRoot = null;
    _isManual = false;
    _searchedPaths = searched;
    return false;
  }

  /// Records [path] as the SDK to use. Accepts either the SDK root directory or
  /// the `flutter` executable itself. Returns false if it isn't a usable SDK.
  Future<bool> setSdkPath(String path) async {
    final binary = _resolveBinary(path);
    if (binary == null || !await _adopt(binary, isManual: true)) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, binary);
    return true;
  }

  Future<void> clearSdkPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await detectFlutterSdk();
  }

  Future<Map<String, dynamic>> getFlutterInfo() async {
    if (_flutterPath == null) {
      await detectFlutterSdk();
    }

    return {
      'path': _flutterPath,
      'version': _flutterVersion,
      'sdkRoot': _sdkRoot,
      'isAvailable': _flutterPath != null,
      'isManual': _isManual,
      'searchedPaths': _searchedPaths,
    };
  }

  Future<bool> validateFlutterSdk() => detectFlutterSdk();

  /// Environment for spawning `flutter`, with the SDK's own `bin` directory and
  /// the usual tool locations on `PATH` so nested tools (`dart`, `git`) resolve.
  Map<String, String> buildEnvironment() {
    final env = Map<String, String>.from(Platform.environment);

    final home = env['HOME'];
    if (home != null && home.contains('/Library/Containers/')) {
      final match = RegExp(r'^/Users/[^/]+').firstMatch(home);
      if (match != null) {
        env['HOME'] = match.group(0)!;
      }
    }

    final parts = <String>{
      if (_flutterPath != null) p.dirname(_flutterPath!),
      '/opt/homebrew/bin',
      '/usr/local/bin',
      '/usr/bin',
      '/bin',
      '/usr/sbin',
      '/sbin',
      ...(env['PATH'] ?? '').split(':').where((e) => e.isNotEmpty),
    };
    env['PATH'] = parts.join(':');
    return env;
  }

  /// Maps a user-supplied path to the `flutter` executable. Accepts the SDK
  /// root, its `bin` directory, or the executable itself.
  String? _resolveBinary(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;

    final exe = Platform.isWindows ? 'flutter.bat' : 'flutter';
    final candidates = [
      trimmed,
      p.join(trimmed, exe),
      p.join(trimmed, 'bin', exe),
    ];

    for (final candidate in candidates) {
      final file = File(candidate);
      if (file.existsSync() &&
          FileSystemEntity.typeSync(candidate) != FileSystemEntityType.directory) {
        return candidate;
      }
    }
    return null;
  }

  Future<bool> _adopt(String binary, {required bool isManual}) async {
    final version = await _readVersion(binary);
    if (version == null) return false;

    _flutterPath = binary;
    _flutterVersion = version;
    _sdkRoot = _sdkRootFor(binary);
    _isManual = isManual;
    return true;
  }

  Future<String?> _readVersion(String binary) async {
    try {
      final result = await Process.run(
        binary,
        ['--version'],
        environment: buildEnvironment(),
        runInShell: false,
      ).timeout(_lookupTimeout);

      if (result.exitCode != 0) return null;

      final line = result.stdout
          .toString()
          .split('\n')
          .map((l) => l.trim())
          .firstWhere((l) => l.isNotEmpty, orElse: () => '');
      return line.isEmpty ? null : line;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _savedPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      return (saved == null || saved.isEmpty) ? null : saved;
    } catch (_) {
      return null;
    }
  }

  /// Asks the user's login shell where `flutter` is. `-i` and `-l` together pick
  /// up PATH set in either `.zshrc` or `.zprofile`, which is where Homebrew and
  /// version managers install their shims.
  Future<String?> _resolveViaLoginShell() async {
    if (Platform.isWindows) return null;

    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
    if (!File(shell).existsSync()) return null;

    try {
      final result = await Process.run(
        shell,
        ['-ilc', 'command -v flutter || which flutter'],
        environment: buildEnvironment(),
        runInShell: false,
      ).timeout(_lookupTimeout);

      // Interactive shells may print banners, so take the last line that looks
      // like an existing executable path.
      final candidates = result.stdout
          .toString()
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.startsWith('/') && File(l).existsSync());

      return candidates.isEmpty ? null : candidates.last;
    } catch (_) {
      return null;
    }
  }

  List<String> _wellKnownBinaries() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';

    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      return [
        r'C:\flutter\bin\flutter.bat',
        r'C:\src\flutter\bin\flutter.bat',
        if (localAppData.isNotEmpty)
          p.join(localAppData, 'flutter', 'bin', 'flutter.bat'),
        if (home.isNotEmpty) p.join(home, 'flutter', 'bin', 'flutter.bat'),
      ];
    }

    final roots = <String>[
      // Homebrew
      '/opt/homebrew/bin/flutter',
      '/usr/local/bin/flutter',
      '/opt/homebrew/share/flutter/bin/flutter',
      '/usr/local/share/flutter/bin/flutter',
      // Linux package managers
      '/snap/bin/flutter',
      '/opt/flutter/bin/flutter',
      '/usr/local/flutter/bin/flutter',
      if (home.isNotEmpty) ...[
        // Version managers
        '$home/fvm/default/bin/flutter',
        '$home/.fvm/default/bin/flutter',
        '$home/.asdf/shims/flutter',
        '$home/.local/share/mise/shims/flutter',
        '$home/.puro/envs/default/flutter/bin/flutter',
        // Common manual installs
        '$home/flutter/bin/flutter',
        '$home/development/flutter/bin/flutter',
        '$home/Developer/flutter/bin/flutter',
        '$home/sdk/flutter/bin/flutter',
        '$home/src/flutter/bin/flutter',
      ],
    ];

    return [...roots, ..._homebrewCaskBinaries()];
  }

  /// `brew install --cask flutter` keeps the SDK under `Caskroom/flutter/<version>`,
  /// which is version-specific and so cannot be hardcoded.
  List<String> _homebrewCaskBinaries() {
    final found = <String>[];
    for (final prefix in ['/opt/homebrew', '/usr/local']) {
      final caskroom = Directory('$prefix/Caskroom/flutter');
      if (!caskroom.existsSync()) continue;
      for (final entry in caskroom.listSync().whereType<Directory>()) {
        found.add(p.join(entry.path, 'flutter', 'bin', 'flutter'));
      }
    }
    return found;
  }

  /// The SDK root, following symlinks so Homebrew's `bin/flutter` shim maps back
  /// to the real Caskroom directory.
  String? _sdkRootFor(String binary) {
    try {
      final resolved = File(binary).resolveSymbolicLinksSync();
      final binDir = p.dirname(resolved);
      if (p.basename(binDir) == 'bin') {
        return p.dirname(binDir);
      }
      return binDir;
    } catch (_) {
      return null;
    }
  }
}
