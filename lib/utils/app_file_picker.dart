import 'package:flutter/services.dart';

/// Native macOS file/folder pickers hosted in Runner (works with macos_ui).
class AppFilePicker {
  static const _channel = MethodChannel('drop_xide/file_picker');

  static Future<String?> pickDirectory({String? confirmButtonText}) async {
    final path = await _channel.invokeMethod<String>('pickDirectory');
    return path;
  }

  static Future<String?> pickJsonFile({String? confirmButtonText}) async {
    final path = await _channel.invokeMethod<String>(
      'pickFile',
      <String, dynamic>{
        'extensions': <String>['json'],
      },
    );
    return path;
  }
}
