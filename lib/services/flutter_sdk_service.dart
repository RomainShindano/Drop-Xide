import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Locates the Flutter SDK on the host machine.
///
/// A GUI app launched from Finder or the Dock does not inherit the shell's
/// `PATH`, and App Sandbox blocks direct reads of Homebrew paths such as
/// `/opt/homebrew/Caskroom`. Detection therefore tries, in order:
///
/// 1. a path the user chose explicitly (persisted),
/// 2. the user's login shell running `flutter --version` (works for Homebrew),
/// 3. Homebrew shim symlinks via `readlink`,
/// 4. well-known install locations (fvm, asdf, mise, manual).
class FlutterSdkService {
  static const _prefsKey = 'flutter_sdk_path';
  static const _shellPathMarker = '__DROPXIDE_FLUTTER_PATH__';
  static const _lookupTimeout = Duration(seconds: 20);

  String? _flutterPath;
  String? _flutterVersion;
  String? _sdkRoot;
  bool _isManual = false;
  bool _usesShellRunner = false;
  List<String> _searchedPaths = const [];

  String? get flutterPath => _flutterPath;
  String? get flutterVersion => _flutterVersion;
  String? get sdkRoot => _sdkRoot;
  bool get isFlutterAvailable => _flutterPath != null || _usesShellRunner;
  bool get usesShellRunner => _usesShellRunner;

  Future<bool> detectFlutterSdk() async {
    final searched = <String>[];

    try {
      final manual = await _savedPath();
      if (manual != null) {
        searched.add(manual);
        if (await setSdkPath(manual)) {
          _searchedPaths = searched;
          return true;
        }
      }

      final fromShell = await _probeViaLoginShell();
      if (fromShell != null) {
        searched.add(fromShell.binary);
        if (await _adoptFromProbe(fromShell, isManual: false)) {
          _searchedPaths = searched;
          return true;
        }
      }

      for (final candidate in _resolveHomebrewSymlinks()) {
        searched.add(candidate);
        if (await _adopt(candidate, isManual: false)) {
          _searchedPaths = searched;
          return true;
        }
      }

      for (final candidate in _wellKnownBinaries()) {
        searched.add(candidate);
        if (await _adopt(candidate, isManual: false)) {
          _searchedPaths = searched;
          return true;
        }
      }
    } catch (_) {
      // Detection probes paths the app may not be allowed to read. Treat any
      // unexpected failure as "not found" rather than letting it surface as a
      // build error.
    }

    _clearState();
    _searchedPaths = searched;
    return false;
  }

  /// Records a validated SDK pick from the native open panel.
  Future<bool> adoptManualPick({
    required String sdkRoot,
    String? version,
  }) async {
    final binary = p.join(
      sdkRoot,
      'bin',
      Platform.isWindows ? 'flutter.bat' : 'flutter',
    );

    _flutterPath = binary;
    _flutterVersion = version ?? await _readVersionAt(binary, sdkRoot);
    _flutterVersion ??= _structuralVersion(sdkRoot);
    if (_flutterVersion == null) return false;

    _sdkRoot = sdkRoot;
    _isManual = true;

    final directVersion = await _readVersionWithEnv(
      binary,
      _envForSdk(sdkRoot, binary),
    );
    _usesShellRunner = directVersion == null || !Platform.isWindows;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, binary);
      await prefs.setString('${_prefsKey}_root', sdkRoot);
    } catch (_) {
      // The SDK still works for this session even if the choice can't be saved.
    }
    return true;
  }

  /// Records [path] as the SDK to use. Accepts the SDK root, a Homebrew version
  /// folder, the bin directory, or the `flutter` executable. Returns false when
  /// the selection cannot be verified.
  Future<bool> setSdkPath(String path) async {
    final sdkRoot = await _normalizeSelection(path);
    if (sdkRoot == null) return false;

    final binary = p.join(
      sdkRoot,
      'bin',
      Platform.isWindows ? 'flutter.bat' : 'flutter',
    );

    final version = await _readVersionAt(binary, sdkRoot) ?? _structuralVersion(sdkRoot);
    if (version == null) return false;

    final directVersion = await _readVersionWithEnv(
      binary,
      _envForSdk(sdkRoot, binary),
    );

    _flutterPath = binary;
    _flutterVersion = version;
    _sdkRoot = sdkRoot;
    _isManual = true;
    _usesShellRunner = directVersion == null || !Platform.isWindows;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, binary);
      await prefs.setString('${_prefsKey}_root', sdkRoot);
    } catch (_) {
      // The SDK still works for this session even if the choice can't be saved.
    }
    return true;
  }

  Future<void> clearSdkPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      await prefs.remove('${_prefsKey}_root');
    } catch (_) {
      // Fall through to re-detection regardless.
    }
    await detectFlutterSdk();
  }

  Future<Map<String, dynamic>> getFlutterInfo() async {
    if (!isFlutterAvailable) {
      await detectFlutterSdk();
    }

    return {
      'path': _flutterPath,
      'version': _flutterVersion,
      'sdkRoot': _sdkRoot,
      'isAvailable': isFlutterAvailable,
      'isManual': _isManual,
      'usesShellRunner': _usesShellRunner,
      'searchedPaths': _searchedPaths,
    };
  }

  Future<bool> validateFlutterSdk() => detectFlutterSdk();

  /// Starts a `flutter` process. On macOS, Homebrew's `bin/flutter` is a shell
  /// script that App Sandbox blocks executing directly — even through
  /// `zsh -ilc '/path/flutter …'`. The script is invoked via `/bin/sh` instead.
  Future<Process> startFlutterProcess(
    List<String> args, {
    String? workingDirectory,
  }) async {
    final env = buildEnvironment();

    if (Platform.isWindows) {
      if (_flutterPath != null) {
        return Process.start(
          _flutterPath!,
          args,
          workingDirectory: workingDirectory,
          environment: env,
          runInShell: false,
        );
      }
      return Process.start(
        'cmd.exe',
        ['/c', 'flutter ${_shellJoin(args)}'],
        workingDirectory: workingDirectory,
        environment: env,
      );
    }

    if (_flutterPath != null) {
      return Process.start(
        '/bin/sh',
        [_flutterPath!, ...args],
        workingDirectory: workingDirectory,
        environment: env,
      );
    }

    final shell = _shellExecutable();
    return Process.start(
      shell,
      ['-ilc', 'flutter ${_shellJoin(args)}'],
      workingDirectory: workingDirectory,
      environment: env,
    );
  }

  /// Environment for spawning `flutter`, with the SDK's own `bin` directory and
  /// the usual tool locations on `PATH` so nested tools (`dart`, `git`) resolve.
  Map<String, String> buildEnvironment() {
    final env = Map<String, String>.from(Platform.environment);

    final home = _realHome(env['HOME']);
    if (home != null) {
      env['HOME'] = home;
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
    if (_sdkRoot != null) {
      env['FLUTTER_ROOT'] = _sdkRoot!;
    }
    return env;
  }

  void _clearState() {
    _flutterPath = null;
    _flutterVersion = null;
    _sdkRoot = null;
    _isManual = false;
    _usesShellRunner = false;
  }

  String _shellExecutable() {
    if (Platform.isWindows) return 'cmd.exe';
    final shell = Platform.environment['SHELL'];
    if (shell != null && shell.isNotEmpty && _isFile(shell)) {
      return shell;
    }
    return '/bin/zsh';
  }

  String _shellJoin(List<String> args) {
    return args.map(_shellEscape).join(' ');
  }

  String _shellEscape(String arg) {
    if (arg.isEmpty) return "''";
    return "'${arg.replaceAll("'", r"'\''")}'";
  }

  /// Resolves a panel selection to the SDK root directory.
  Future<String?> _normalizeSelection(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;

    final exe = Platform.isWindows ? 'flutter.bat' : 'flutter';

    if (p.basename(trimmed) == exe && _isFile(trimmed)) {
      return _sdkRootFor(trimmed);
    }

    if (p.basename(trimmed) == 'bin') {
      final binary = p.join(trimmed, exe);
      final root = p.dirname(trimmed);
      if (await _looksLikeSdkRoot(root, binary)) return root;
    }

    final atRoot = p.join(trimmed, 'bin', exe);
    if (await _looksLikeSdkRoot(trimmed, atRoot)) return trimmed;

    // Homebrew Caskroom: user often picks the version folder (…/3.29.0).
    final nestedRoot = p.join(trimmed, 'flutter');
    final atNested = p.join(nestedRoot, 'bin', exe);
    if (await _looksLikeSdkRoot(nestedRoot, atNested)) return nestedRoot;

    // Homebrew Caskroom parent: …/Caskroom/flutter (contains version folders).
    if (_isCaskroomParent(trimmed)) {
      final discovered = await _discoverCaskroomSdk(trimmed);
      if (discovered != null) return discovered;
    }

    return null;
  }

  bool _isCaskroomParent(String path) {
    return p.basename(path) == 'flutter' &&
        p.basename(p.dirname(path)) == 'Caskroom';
  }

  Future<String?> _discoverCaskroomSdk(String caskroom) async {
    final candidates = <String>[];

    for (final version in _subdirectories(caskroom)) {
      final sdkRoot = p.join(version.path, 'flutter');
      final binary = p.join(sdkRoot, 'bin', 'flutter');
      candidates.add(sdkRoot);
      if (await _looksLikeSdkRoot(sdkRoot, binary)) return sdkRoot;
    }

    return _discoverCaskroomViaShell(caskroom, candidates);
  }

  Future<String?> _discoverCaskroomViaShell(
    String caskroom,
    List<String> alreadyTried,
  ) async {
    if (Platform.isWindows) return null;

    try {
      final result = await Process.run(
        _shellExecutable(),
        [
          '-ilc',
          'for d in "$caskroom"/*/flutter/bin/flutter; do '
          r'[ -e "$d" ] || continue; '
          r'"$d" --version 2>/dev/null | head -n 1 && echo "$d" && break; '
          'done',
        ],
        environment: buildEnvironment(),
        runInShell: false,
      ).timeout(_lookupTimeout);

      if (result.exitCode != 0) return null;

      final lines = result.stdout
          .toString()
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (lines.length < 2 || !lines.first.startsWith('Flutter ')) {
        return null;
      }

      final binary = lines.last;
      return _sdkRootFor(binary);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _looksLikeSdkRoot(String sdkRoot, String binary) async {
    if (_isFile(binary)) return true;
    return await _readVersionAt(binary, sdkRoot) != null;
  }

  bool _isFile(String path) {
    try {
      return FileSystemEntity.typeSync(path) == FileSystemEntityType.file;
    } catch (_) {
      return false;
    }
  }

  List<Directory> _subdirectories(String path) {
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) return const [];
      return dir.listSync(followLinks: false).whereType<Directory>().toList();
    } catch (_) {
      return const [];
    }
  }

  String? _realHome(String? home) {
    if (home == null || home.isEmpty) return null;
    if (home.contains('/Library/Containers/')) {
      final match = RegExp(r'^/Users/[^/]+').firstMatch(home);
      return match?.group(0) ?? home;
    }
    return home;
  }

  Future<bool> _adopt(String binary, {required bool isManual}) async {
    final sdkRoot = _sdkRootFor(binary);
    if (sdkRoot == null) return false;

    final version = await _readVersionAt(binary, sdkRoot);
    if (version == null) return false;

    final directVersion = await _readVersionWithEnv(
      binary,
      _envForSdk(sdkRoot, binary),
    );

    _flutterPath = binary;
    _flutterVersion = version;
    _sdkRoot = sdkRoot;
    _isManual = isManual;
    _usesShellRunner = directVersion == null || !Platform.isWindows;
    return true;
  }

  Future<bool> _adoptFromProbe(
    _FlutterProbe probe, {
    required bool isManual,
  }) async {
    final directVersion = await _readVersion(probe.binary);
    _flutterPath = probe.binary;
    _flutterVersion = directVersion ?? probe.version;
    _sdkRoot = _sdkRootFor(probe.binary);
    _isManual = isManual;
    _usesShellRunner = directVersion == null || !Platform.isWindows;
    return true;
  }

  Future<String?> _readVersion(String binary) async {
    final sdkRoot = _sdkRootFor(binary);
    if (sdkRoot == null) return null;
    return _readVersionAt(binary, sdkRoot);
  }

  Future<String?> _readVersionAt(String binary, String sdkRoot) async {
    final direct = await _readVersionWithEnv(
      binary,
      _envForSdk(sdkRoot, binary),
    );
    if (direct != null) return direct;
    return _readVersionViaShellAt(binary, sdkRoot);
  }

  Future<String?> _readVersionWithEnv(
    String binary,
    Map<String, String> environment,
  ) async {
    try {
      if (!Platform.isWindows) {
        final viaShell = await Process.run(
          '/bin/sh',
          [binary, '--version'],
          environment: environment,
          runInShell: false,
        ).timeout(_lookupTimeout);
        if (viaShell.exitCode == 0) {
          final line = _firstNonEmptyLine(viaShell.stdout.toString());
          if (line != null && line.startsWith('Flutter ')) return line;
        }
      }

      final result = await Process.run(
        binary,
        ['--version'],
        environment: environment,
        runInShell: false,
      ).timeout(_lookupTimeout);

      if (result.exitCode != 0) return null;
      return _firstNonEmptyLine(result.stdout.toString());
    } catch (_) {
      return null;
    }
  }

  String? _structuralVersion(String sdkRoot) {
    final binary = p.join(sdkRoot, 'bin', 'flutter');
    final packages = p.join(sdkRoot, 'packages', 'flutter');
    final versionFile = File(p.join(sdkRoot, 'version'));

    if (!_isFile(binary)) return null;
    if (!_isDirectory(packages) && !versionFile.existsSync()) return null;

    if (versionFile.existsSync()) {
      final raw = versionFile.readAsStringSync().trim();
      if (raw.isNotEmpty) return 'Flutter $raw';
    }
    return 'Flutter SDK';
  }

  bool _isDirectory(String path) {
    try {
      return FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
    } catch (_) {
      return false;
    }
  }

  Map<String, String> _envForSdk(String sdkRoot, String binary) {
    final env = buildEnvironment();
    env['FLUTTER_ROOT'] = sdkRoot;
    final binDir = p.dirname(binary);
    env['PATH'] = '$binDir:${env['PATH']}';
    return env;
  }

  Future<String?> _readVersionViaShellAt(String binary, String sdkRoot) async {
    if (Platform.isWindows) return null;

    try {
      final result = await Process.run(
        '/bin/sh',
        [binary, '--version'],
        environment: _envForSdk(sdkRoot, binary),
        runInShell: false,
      ).timeout(_lookupTimeout);

      if (result.exitCode != 0) return null;
      final line = _firstNonEmptyLine(result.stdout.toString());
      if (line == null || !line.startsWith('Flutter ')) return null;
      return line;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _savedPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final root = prefs.getString('${_prefsKey}_root');
      if (root != null && root.isNotEmpty) return root;

      final saved = prefs.getString(_prefsKey);
      if (saved == null || saved.isEmpty) return null;
      return _sdkRootFor(saved) ?? saved;
    } catch (_) {
      return null;
    }
  }

  /// Runs `flutter --version` through the login shell. This is the most reliable
  /// auto-detect path for Homebrew installs under App Sandbox.
  Future<_FlutterProbe?> _probeViaLoginShell() async {
    if (Platform.isWindows) return null;

    final shell = _shellExecutable();
    if (!_isFile(shell)) return null;

    try {
      final result = await Process.run(
        shell,
        [
          '-ilc',
          'flutter --version 2>/dev/null | head -n 1; '
          "printf '%s\\n' '$_shellPathMarker'; "
          'command -v flutter 2>/dev/null || which flutter 2>/dev/null',
        ],
        environment: buildEnvironment(),
        runInShell: false,
      ).timeout(_lookupTimeout);

      if (result.exitCode != 0) return null;

      final output = result.stdout.toString();
      final markerIndex = output.indexOf(_shellPathMarker);
      if (markerIndex < 0) return null;

      final version = _firstNonEmptyLine(output.substring(0, markerIndex));
      if (version == null || !version.startsWith('Flutter ')) return null;

      final afterMarker = output.substring(markerIndex + _shellPathMarker.length);
      final binary = afterMarker
          .split('\n')
          .map((line) => line.trim())
          .lastWhere(
            (line) => line.startsWith('/'),
            orElse: () => '',
          );
      if (binary.isEmpty) {
        return _FlutterProbe(binary: 'flutter', version: version);
      }

      return _FlutterProbe(binary: binary, version: version);
    } catch (_) {
      return null;
    }
  }

  List<String> _resolveHomebrewSymlinks() {
    if (Platform.isWindows) return const [];

    final found = <String>[];
    for (final shim in ['/opt/homebrew/bin/flutter', '/usr/local/bin/flutter']) {
      final target = _readSymlinkTarget(shim);
      if (target == null) continue;

      if (p.basename(target) == 'flutter') {
        found.add(target);
        continue;
      }

      found.add(p.join(target, 'bin', 'flutter'));
    }
    return found;
  }

  String? _readSymlinkTarget(String path) {
    try {
      final result = Process.runSync(
        '/usr/bin/readlink',
        [path],
        environment: buildEnvironment(),
      );
      if (result.exitCode != 0) return null;

      var target = result.stdout.toString().trim();
      if (target.isEmpty) return null;
      if (!target.startsWith('/')) {
        target = p.normalize(p.join(p.dirname(path), target));
      }
      return target;
    } catch (_) {
      return null;
    }
  }

  List<String> _wellKnownBinaries() {
    final home = _realHome(Platform.environment['HOME']) ??
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
      '/opt/homebrew/bin/flutter',
      '/usr/local/bin/flutter',
      '/opt/homebrew/share/flutter/bin/flutter',
      '/usr/local/share/flutter/bin/flutter',
      '/snap/bin/flutter',
      '/opt/flutter/bin/flutter',
      '/usr/local/flutter/bin/flutter',
      if (home.isNotEmpty) ...[
        '$home/fvm/default/bin/flutter',
        '$home/.fvm/default/bin/flutter',
        '$home/.asdf/shims/flutter',
        '$home/.local/share/mise/shims/flutter',
        '$home/.puro/envs/default/flutter/bin/flutter',
        '$home/flutter/bin/flutter',
        '$home/development/flutter/bin/flutter',
        '$home/Developer/flutter/bin/flutter',
        '$home/sdk/flutter/bin/flutter',
        '$home/src/flutter/bin/flutter',
      ],
    ];

    return [...roots, ..._homebrewCaskBinaries(home)];
  }

  List<String> _homebrewCaskBinaries(String home) {
    final found = <String>[];
    for (final prefix in ['/opt/homebrew', '/usr/local']) {
      for (final version in _subdirectories('$prefix/Caskroom/flutter')) {
        found.add(p.join(version.path, 'flutter', 'bin', 'flutter'));
      }
    }
    return found;
  }

  String? _firstNonEmptyLine(String text) {
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  String? _sdkRootFor(String binary) {
    if (binary == 'flutter') return null;

    try {
      final resolved = File(binary).resolveSymbolicLinksSync();
      final binDir = p.dirname(resolved);
      if (p.basename(binDir) == 'bin') {
        return p.dirname(binDir);
      }
      return binDir;
    } catch (_) {
      final binDir = p.dirname(binary);
      if (p.basename(binDir) == 'bin') {
        return p.dirname(binDir);
      }
      return null;
    }
  }
}

class _FlutterProbe {
  const _FlutterProbe({required this.binary, required this.version});

  final String binary;
  final String version;
}
