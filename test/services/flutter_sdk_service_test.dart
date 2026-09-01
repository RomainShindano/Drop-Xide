import 'dart:io';

import 'package:drop_xide/services/flutter_sdk_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Creates a directory laid out like a Flutter SDK, with a `bin/flutter` stub
/// that reports a version the way the real tool does.
Directory _fakeSdk() {
  final root = Directory.systemTemp.createTempSync('dropxide_sdk');
  final sdk = Directory(p.join(root.path, 'flutter'))..createSync();
  final bin = Directory(p.join(sdk.path, 'bin'))..createSync();
  final exe = File(p.join(bin.path, 'flutter'))
    ..writeAsStringSync(
      '#!/bin/sh\necho "Flutter 3.99.0 • channel stable • test"\n',
    );
  Process.runSync('chmod', ['755', exe.path]);
  return sdk;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('setSdkPath', () {
    test('accepts the SDK root directory', () async {
      final sdk = _fakeSdk();
      addTearDown(() => sdk.parent.deleteSync(recursive: true));

      final service = FlutterSdkService();

      expect(await service.setSdkPath(sdk.path), isTrue);
      expect(service.flutterPath, p.join(sdk.path, 'bin', 'flutter'));
      expect(service.sdkRoot, sdk.path);
      expect(service.flutterVersion, contains('3.99.0'));
      expect(service.isFlutterAvailable, isTrue);
    });

    test('accepts the bin directory and the executable itself', () async {
      final sdk = _fakeSdk();
      addTearDown(() => sdk.parent.deleteSync(recursive: true));

      final expected = p.join(sdk.path, 'bin', 'flutter');

      final fromBin = FlutterSdkService();
      expect(await fromBin.setSdkPath(p.join(sdk.path, 'bin')), isTrue);
      expect(fromBin.flutterPath, expected);

      final fromExe = FlutterSdkService();
      expect(await fromExe.setSdkPath(expected), isTrue);
      expect(fromExe.flutterPath, expected);
    });

    test('rejects a directory that holds no SDK', () async {
      final empty = Directory.systemTemp.createTempSync('dropxide_empty');
      addTearDown(() => empty.deleteSync(recursive: true));

      final service = FlutterSdkService();

      expect(await service.setSdkPath(empty.path), isFalse);
      expect(service.isFlutterAvailable, isFalse);
      expect(service.flutterPath, isNull);
    });

    test('rejects an empty path', () async {
      expect(await FlutterSdkService().setSdkPath('   '), isFalse);
    });
  });

  group('buildEnvironment', () {
    test('puts the SDK bin directory first on PATH', () async {
      final sdk = _fakeSdk();
      addTearDown(() => sdk.parent.deleteSync(recursive: true));

      final service = FlutterSdkService();
      await service.setSdkPath(sdk.path);

      final path = service.buildEnvironment()['PATH']!.split(':');

      expect(path.first, p.join(sdk.path, 'bin'));
      expect(path, contains('/opt/homebrew/bin'));
      expect(path, contains('/usr/local/bin'));
    });

    test('redirects a sandbox container HOME back to the real home', () {
      final env = FlutterSdkService().buildEnvironment();
      expect(env['HOME'], isNot(contains('/Library/Containers/')));
    });

    test('sets FLUTTER_ROOT after the SDK is chosen', () async {
      final sdk = _fakeSdk();
      addTearDown(() => sdk.parent.deleteSync(recursive: true));

      final service = FlutterSdkService();
      await service.setSdkPath(sdk.path);

      expect(service.buildEnvironment()['FLUTTER_ROOT'], sdk.path);
    });
  });

  group('unreadable locations', () {
    // App Sandbox denies access to paths like /opt/homebrew/Caskroom, and
    // probing them throws PathAccessException rather than returning false.
    test('setSdkPath reports failure instead of throwing', () async {
      final locked = Directory.systemTemp.createTempSync('dropxide_locked');
      Process.runSync('chmod', ['000', locked.path]);
      addTearDown(() {
        Process.runSync('chmod', ['755', locked.path]);
        locked.deleteSync(recursive: true);
      });

      final service = FlutterSdkService();

      expect(
        await service.setSdkPath(p.join(locked.path, 'flutter')),
        isFalse,
      );
      expect(service.isFlutterAvailable, isFalse);
    });

    test('detectFlutterSdk completes rather than propagating an error',
        () async {
      final service = FlutterSdkService();
      await expectLater(service.detectFlutterSdk(), completes);
    });

    test('a saved path that has become unreadable does not throw', () async {
      final locked = Directory.systemTemp.createTempSync('dropxide_saved');
      Process.runSync('chmod', ['000', locked.path]);
      addTearDown(() {
        Process.runSync('chmod', ['755', locked.path]);
        locked.deleteSync(recursive: true);
      });

      SharedPreferences.setMockInitialValues({
        'flutter_sdk_path': p.join(locked.path, 'flutter', 'bin', 'flutter'),
      });

      final service = FlutterSdkService();
      await expectLater(service.detectFlutterSdk(), completes);
    });
  });

  group('getFlutterInfo', () {
    test('reports the manual flag once a path is chosen', () async {
      final sdk = _fakeSdk();
      addTearDown(() => sdk.parent.deleteSync(recursive: true));

      final service = FlutterSdkService();
      await service.setSdkPath(sdk.path);

      final info = await service.getFlutterInfo();

      expect(info['isAvailable'], isTrue);
      expect(info['isManual'], isTrue);
      expect(info['sdkRoot'], sdk.path);
      expect(info['usesShellRunner'], isFalse);
    });

    test('isFlutterAvailable stays true when only shell runner is active', () {
      final service = FlutterSdkService();
      expect(service.isFlutterAvailable, isFalse);
    });
  });

  group('startFlutterProcess', () {
    test('starts the resolved binary directly when available', () async {
      final sdk = _fakeSdk();
      addTearDown(() => sdk.parent.deleteSync(recursive: true));

      final service = FlutterSdkService();
      await service.setSdkPath(sdk.path);

      final process = await service.startFlutterProcess(['--version']);
      addTearDown(() => process.kill());

      final exitCode = await process.exitCode;
      expect(exitCode, 0);
      expect(service.usesShellRunner, isFalse);
    });
  });
}
