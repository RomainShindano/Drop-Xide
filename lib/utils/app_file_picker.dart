import 'package:flutter/services.dart';

import '../models/flutter_sdk_pick_result.dart';

/// Native macOS file/folder pickers hosted in Runner (works with macos_ui).
class AppFilePicker {
  static const _channel = MethodChannel('drop_xide/file_picker');

  static Future<String?> pickDirectory({
    String? dialogTitle,
    String? confirmButtonText,
  }) async {
    final path = await _channel.invokeMethod<String>(
      'pickDirectory',
      <String, dynamic>{
        'dialogTitle': ?dialogTitle,
        'confirmButtonText': ?confirmButtonText,
      },
    );
    return path;
  }

  /// Opens the Flutter SDK picker. Validation runs natively while security-
  /// scoped access from the open panel is still active.
  static Future<FlutterSdkPickResult?> pickFlutterSdk({
    String? dialogTitle,
    String? confirmButtonText,
  }) async {
    try {
      final result = await _channel.invokeMethod<Object>(
        'pickFlutterSdk',
        <String, dynamic>{
          'dialogTitle': ?dialogTitle,
          'confirmButtonText': ?confirmButtonText,
        },
      );

      if (result is Map) {
        final sdkRoot = result['sdkRoot'];
        if (sdkRoot is String && sdkRoot.isNotEmpty) {
          return FlutterSdkPickResult(
            sdkRoot: sdkRoot,
            version: result['version'] as String?,
          );
        }
      }

      return null;
    } on MissingPluginException {
      final path = await pickDirectory(
        dialogTitle: dialogTitle,
        confirmButtonText: confirmButtonText,
      );
      if (path == null) return null;
      return FlutterSdkPickResult(sdkRoot: path);
    } on PlatformException catch (e) {
      if (e.code == 'invalid_sdk') return null;
      rethrow;
    }
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

  /// Re-acquires access to folders and files chosen in earlier sessions.
  ///
  /// App Sandbox grants access to a user-selected path only until the app quits.
  /// Runner stores a security-scoped bookmark for every pick, and this reopens
  /// them so saved project and SDK paths remain readable after a relaunch.
  /// Returns the paths that are usable again; unsandboxed builds return an empty
  /// list because they never lost access.
  static Future<List<String>> restoreAccess() async {
    try {
      final restored = await _channel.invokeListMethod<String>('restoreAccess');
      return restored ?? const [];
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }
}
