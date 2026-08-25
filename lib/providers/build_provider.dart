import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/build_history.dart';
import '../models/build_queue_item.dart';
import '../models/build_template.dart';
import '../models/flutter_project.dart';
import '../services/build_service.dart';
import '../services/build_queue_service.dart';
import '../services/build_template_service.dart';
import '../services/notification_service.dart';

class BuildProvider extends ChangeNotifier {
  final BuildService _buildService = BuildService();
  final BuildQueueService _queueService = BuildQueueService.instance;
  final BuildTemplateService _templateService = BuildTemplateService();
  final NotificationService _notificationService = NotificationService.instance;

  List<BuildHistory> _buildHistory = [];
  List<BuildQueueItem> _queueItems = [];
  List<BuildQueueItem> _runningBuilds = [];
  List<BuildTemplate> _templates = [];
  BuildHistory? _currentBuild;
  bool _isLoading = false;
  String? _error;
  final List<String> _logs = [];

  StreamSubscription<BuildHistory>? _buildSub;
  StreamSubscription<String>? _logSub;
  StreamSubscription<FlutterProject>? _projectSub;
  StreamSubscription<List<BuildQueueItem>>? _queueSub;
  StreamSubscription<List<BuildQueueItem>>? _runningSub;

  void Function(FlutterProject project)? onProjectUpdated;

  List<BuildHistory> get buildHistory => _buildHistory;
  List<BuildQueueItem> get queueItems => _queueItems;
  List<BuildQueueItem> get runningBuilds => _runningBuilds;
  List<BuildTemplate> get templates => _templates;
  BuildHistory? get currentBuild => _currentBuild;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get logs => _logs;
  bool get isBuilding =>
      _currentBuild?.status == BuildStatus.running || _buildService.isBuilding;
  int get maxConcurrentBuilds => _queueService.maxConcurrentBuilds;

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
      
      // Send notification on build completion
      if (build.isCompleted) {
        if (build.status == BuildStatus.success) {
          _notificationService.showBuildCompleted(build);
        } else if (build.status == BuildStatus.failed) {
          _notificationService.showBuildFailed(build);
        }
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

    _queueSub = _queueService.queueStream.listen((items) {
      _queueItems = items;
      notifyListeners();
    });

    _runningSub = _queueService.runningBuildsStream.listen((items) {
      _runningBuilds = items;
      notifyListeners();
    });

    loadTemplates();
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

  Future<BuildQueueItem> addToQueue(
    FlutterProject project,
    BuildConfig config, {
    int priority = 0,
  }) async {
    try {
      final queueItem = await _queueService.addToBuildQueue(
        project,
        config,
        priority: priority,
      );
      return queueItem;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelQueueItem(String id) async {
    await _queueService.cancelQueueItem(id);
  }

  Future<void> changeQueuePriority(String id, int newPriority) async {
    await _queueService.changePriority(id, newPriority);
  }

  void setMaxConcurrentBuilds(int max) {
    _queueService.setMaxConcurrentBuilds(max);
    notifyListeners();
  }

  Future<void> loadTemplates() async {
    try {
      _templates = await _templateService.getTemplates();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<BuildTemplate> saveTemplate({
    required String name,
    String? description,
    required BuildConfig buildConfig,
  }) async {
    try {
      final template = await _templateService.saveTemplate(
        name: name,
        description: description,
        buildConfig: buildConfig,
      );
      _templates.insert(0, template);
      notifyListeners();
      return template;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTemplate(String id) async {
    await _templateService.deleteTemplate(id);
    _templates.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> toggleTemplateFavorite(String id) async {
    await _templateService.toggleFavorite(id);
    await loadTemplates();
  }

  Future<void> useTemplate(String id) async {
    await _templateService.incrementUsageCount(id);
    await loadTemplates();
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
    _queueSub?.cancel();
    _runningSub?.cancel();
    _buildService.dispose();
    super.dispose();
  }
}
