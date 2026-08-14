import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:process_run/shell.dart';

class FlutterSdkService {
  String? _flutterPath;
  String? _flutterVersion;

  Future<bool> detectFlutterSdk() async {
    try {
      final result = await Shell().run('flutter --version');
      if (result.isNotEmpty) {
        _flutterVersion = result.first.stdout.toString().split('\n').first;
        final whichResult = await Shell().run('which flutter');
        if (whichResult.isNotEmpty) {
          _flutterPath = whichResult.first.stdout.toString().trim();
        }
        return true;
      }
    } catch (e) {
      _flutterPath = null;
      _flutterVersion = null;
    }
    return false;
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
    return await detectFlutterSdk();
  }

  String? get flutterPath => _flutterPath;
  String? get flutterVersion => _flutterVersion;
  bool get isFlutterAvailable => _flutterPath != null;
}
