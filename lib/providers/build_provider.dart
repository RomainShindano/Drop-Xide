import 'dart:async';

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

  StreamSubscription<BuildHistory>? _buildSub;
  StreamSubscription<String>? _logSub;
  StreamSubscription<FlutterProject>? _projectSub;

  void Function(FlutterProject project)? onProjectUpdated;

  List<BuildHistory> get buildHistory => _buildHistory;
  BuildHistory? get currentBuild => _currentBuild;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get logs => _logs;
  bool get isBuilding =>
      _currentBuild?.status == BuildStatus.running || _buildService.isBuilding;

  BuildProvider() {
    _buildSub = _buildService.buildStream.listen((build) {
      final index = _buildHistory.indexWhere((b) => b.id == build.id);
      if (index != -1) {
        _buildHistory[index] = build;
      } else {
        _buildHistory.insert(0, build);
      }
      if (_currentBuild?.id == build.id || _currentBuild == null) {
        _currentBuild = build;
      }
      notifyListeners();
    });

    _logSub = _buildService.logStream.listen((log) {
      _logs.add(log);
      notifyListeners();
    });

    _projectSub = _buildService.projectUpdateStream.listen((project) {
      onProjectUpdated?.call(project);
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
      rethrow;
    }
  }

  Future<void> cancelBuild() async {
    await _buildService.cancelBuild();
  }

  Future<void> deleteBuildHistory(String id) async {
    await _buildService.deleteBuildHistory(id);
    _buildHistory.removeWhere((b) => b.id == id);
    if (_currentBuild?.id == id) {
      _currentBuild = null;
    }
    notifyListeners();
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
    _buildSub?.cancel();
    _logSub?.cancel();
    _projectSub?.cancel();
    _buildService.dispose();
    super.dispose();
  }
}
