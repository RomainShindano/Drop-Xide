import 'package:flutter/foundation.dart';
import '../models/build_history.dart';
import '../models/flutter_project.dart';
import '../services/build_service.dart';

class BuildProvider extends ChangeNotifier {
  final BuildService _buildService = BuildService();
  
  List<BuildHistory> _buildHistory = [];
  BuildHistory? _currentBuild;
  bool _isLoading = false;
  String? _error;
  final List<String> _logs = [];

  List<BuildHistory> get buildHistory => _buildHistory;
  BuildHistory? get currentBuild => _currentBuild;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get logs => _logs;

  BuildProvider() {
    _buildService.buildStream.listen((build) {
      final index = _buildHistory.indexWhere((b) => b.id == build.id);
      if (index != -1) {
        _buildHistory[index] = build;
      } else {
        _buildHistory.insert(0, build);
      }
      if (_currentBuild?.id == build.id) {
        _currentBuild = build;
      }
      notifyListeners();
    });

    _buildService.logStream.listen((log) {
      _logs.add(log);
      notifyListeners();
    });
  }

  Future<void> loadBuildHistory({String? projectId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _buildHistory = await _buildService.getBuildHistory(projectId: projectId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startBuild(FlutterProject project, BuildConfig config) async {
    _logs.clear();
    _error = null;
    notifyListeners();

    try {
      _currentBuild = await _buildService.startBuild(project, config);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _buildService.dispose();
    super.dispose();
  }
}
