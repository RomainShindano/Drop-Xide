import 'package:flutter/services.dart';

/// Native macOS file/folder pickers hosted in Runner (works with macos_ui).
class AppFilePicker {
  static const _channel = MethodChannel('drop_xide/file_picker');

  static Future<String?> pickDirectory({String? confirmButtonText}) async {
    final path = await _channel.invokeMethod<String>('pickDirectory');
    return path;
  }

  static Future<String?> pickJsonFile({String? confirmButtonText}) async {
    return pickFile(fileExtension: 'json', confirmButtonText: confirmButtonText);
  }

  static Future<String?> pickFile({
    String? dialogTitle,
    String? fileExtension,
    List<String>? extensions,
    String? confirmButtonText,
  }) async {
    final allowed = <String>[
      if (fileExtension != null && fileExtension.isNotEmpty) fileExtension,
      ...?extensions,
    ];
    final path = await _channel.invokeMethod<String>(
      'pickFile',
      <String, dynamic>{
        if (allowed.isNotEmpty) 'extensions': allowed,
        'dialogTitle': ?dialogTitle,
        'confirmButtonText': ?confirmButtonText,
      },
    );
    return path;
  }
}
