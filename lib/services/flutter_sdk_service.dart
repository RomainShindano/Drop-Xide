import 'dart:io';

class FlutterSdkService {
  String? _flutterPath;
  String? _flutterVersion;

  Future<bool> detectFlutterSdk() async {
    try {
      final which = await Process.run(
        '/usr/bin/which',
        ['flutter'],
        environment: _loginEnvironment(),
        runInShell: false,
      );
      final resolved = which.stdout.toString().trim().split('\n').firstWhere(
            (line) => line.isNotEmpty,
            orElse: () => '',
          );

      final flutterBin = resolved.isNotEmpty
          ? resolved
          : _fallbackFlutterPaths().firstWhere(
              (p) => File(p).existsSync(),
              orElse: () => '',
            );

      if (flutterBin.isEmpty) {
        _flutterPath = null;
        _flutterVersion = null;
        return false;
      }

      final version = await Process.run(
        flutterBin,
        ['--version'],
        environment: _loginEnvironment(),
        runInShell: false,
      );

      if (version.exitCode != 0) {
        _flutterPath = null;
        _flutterVersion = null;
        return false;
      }

      _flutterPath = flutterBin;
      _flutterVersion = version.stdout.toString().split('\n').first.trim();
      return true;
    } catch (_) {
      _flutterPath = null;
      _flutterVersion = null;
      return false;
    }
  }

  Map<String, String> _loginEnvironment() {
    final env = Map<String, String>.from(Platform.environment);
    final home = env['HOME'];
    // Avoid leftover App Sandbox container paths as cwd/home for tool lookup.
    if (home != null && home.contains('/Library/Containers/')) {
      final match = RegExp(r'^/Users/[^/]+').firstMatch(home);
      if (match != null) {
        env['HOME'] = match.group(0)!;
      }
    }

    final path = env['PATH'] ?? '';
    const extras = [
      '/opt/homebrew/bin',
      '/usr/local/bin',
      '/usr/bin',
      '/bin',
    ];
    final parts = <String>{
      ...extras,
      ...path.split(':').where((p) => p.isNotEmpty),
    };
    env['PATH'] = parts.join(':');
    return env;
  }

  List<String> _fallbackFlutterPaths() {
    final home = Platform.environment['HOME'] ?? '';
    return [
      '/opt/homebrew/bin/flutter',
      '/usr/local/bin/flutter',
      if (home.isNotEmpty) '$home/flutter/bin/flutter',
      if (home.isNotEmpty) '$home/development/flutter/bin/flutter',
      '/opt/homebrew/share/flutter/bin/flutter',
    ];
  }

  Future<Map<String, dynamic>> getFlutterInfo() async {
    if (_flutterPath == null) {
      await detectFlutterSdk();
    }

    return {
      'path': _flutterPath,
      'version': _flutterVersion,
      'isAvailable': _flutterPath != null,
    };
  }

  Future<bool> validateFlutterSdk() async {
    return detectFlutterSdk();
  }

  String? get flutterPath => _flutterPath;
  String? get flutterVersion => _flutterVersion;
  bool get isFlutterAvailable => _flutterPath != null;
}
