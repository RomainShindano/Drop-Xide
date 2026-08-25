import 'package:flutter/foundation.dart';
import '../models/google_service_account.dart';
import '../services/flutter_sdk_service.dart';
import '../services/google_play_service.dart';

class SettingsProvider extends ChangeNotifier {
  final FlutterSdkService _sdkService = FlutterSdkService();
  final GooglePlayService _playService = GooglePlayService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _flutterInfo = {
    'path': null,
    'version': null,
    'isAvailable': false,
  };
  List<GoogleServiceAccount> _accounts = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get flutterInfo => _flutterInfo;
  List<GoogleServiceAccount> get accounts => _accounts;
  bool get isFlutterAvailable => _flutterInfo['isAvailable'] == true;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _flutterInfo = await _sdkService.getFlutterInfo();
      _accounts = await _playService.getServiceAccounts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSdk() async {
    await _sdkService.detectFlutterSdk();
    _flutterInfo = await _sdkService.getFlutterInfo();
    notifyListeners();
  }

  /// Points Drop-Xide at a specific SDK. Accepts the SDK root directory or the
  /// `flutter` executable. Returns false when the path is not a usable SDK.
  Future<bool> setFlutterSdkPath(String path) async {
    final ok = await _sdkService.setSdkPath(path);
    _flutterInfo = await _sdkService.getFlutterInfo();
    _error = ok
        ? null
        : 'No Flutter SDK found at $path. Choose the SDK folder itself '
            '(the one containing bin/flutter).';
    notifyListeners();
    return ok;
  }

  Future<void> clearFlutterSdkPath() async {
    await _sdkService.clearSdkPath();
    _flutterInfo = await _sdkService.getFlutterInfo();
    _error = null;
    notifyListeners();
  }

  Future<void> addServiceAccount(String name, String credentialsPath) async {
    final account =
        await _playService.addServiceAccount(name, credentialsPath);
    _accounts.insert(0, account);
    notifyListeners();
  }

  Future<void> deleteServiceAccount(String id) async {
    await _playService.deleteServiceAccount(id);
    _accounts.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
