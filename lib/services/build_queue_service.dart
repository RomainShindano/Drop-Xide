import 'dart:async';
import 'dart:collection';
import 'package:uuid/uuid.dart';
import '../models/build_queue_item.dart';
import '../models/flutter_project.dart';
import '../services/build_service.dart';
import '../services/database_service.dart';
import 'dart:convert';

class BuildQueueService {
  static final BuildQueueService instance = BuildQueueService._internal();
  
  BuildQueueService._internal();

  final DatabaseService _db = DatabaseService.instance;
  final BuildService _buildService = BuildService();
  final _uuid = const Uuid();

  final Queue<BuildQueueItem> _queue = Queue();
  final List<BuildQueueItem> _runningBuilds = [];
  int _maxConcurrentBuilds = 2;
  bool _isProcessing = false;

  final _queueStreamController = StreamController<List<BuildQueueItem>>.broadcast();
  final _runningBuildsStreamController = StreamController<List<BuildQueueItem>>.broadcast();

  Stream<List<BuildQueueItem>> get queueStream => _queueStreamController.stream;
  Stream<List<BuildQueueItem>> get runningBuildsStream => _runningBuildsStreamController.stream;

  int get maxConcurrentBuilds => _maxConcurrentBuilds;
  int get queueLength => _queue.length;
  int get runningBuildsCount => _runningBuilds.length;

  void setMaxConcurrentBuilds(int max) {
    _maxConcurrentBuilds = max.clamp(1, 10);
    _processQueue();
  }

  Future<BuildQueueItem> addToBuildQueue(
    FlutterProject project,
    BuildConfig config, {
    int priority = 0,
  }) async {
    final queueItem = BuildQueueItem(
      id: _uuid.v4(),
      projectId: project.id,
      projectName: project.name,
      buildConfig: config,
      queuedAt: DateTime.now(),
      status: BuildQueueStatus.queued,
      priority: priority,
    );

    await _saveQueueItem(queueItem);
    _queue.add(queueItem);
    _notifyQueueUpdate();
    
    _processQueue();

    return queueItem;
  }

  Future<void> cancelQueueItem(String id) async {
    // Remove from queue if not started
    final queueItem = _queue.firstWhere(
      (item) => item.id == id,
      orElse: () => _runningBuilds.firstWhere(
        (item) => item.id == id,
        orElse: () => throw Exception('Queue item not found'),
      ),
    );

    if (queueItem.status == BuildQueueStatus.queued) {
      _queue.remove(queueItem);
      final cancelled = queueItem.copyWith(
        status: BuildQueueStatus.cancelled,
        completedAt: DateTime.now(),
      );
      await _updateQueueItem(cancelled);
      _notifyQueueUpdate();
    } else if (queueItem.status == BuildQueueStatus.running) {
      // Mark as cancelled, the worker will handle cleanup
      final cancelled = queueItem.copyWith(
        status: BuildQueueStatus.cancelled,
      );
      _runningBuilds[_runningBuilds.indexOf(queueItem)] = cancelled;
      await _updateQueueItem(cancelled);
      _notifyRunningBuildsUpdate();
    }
  }

  Future<void> changePriority(String id, int newPriority) async {
    final index = _queue.toList().indexWhere((item) => item.id == id);
    if (index != -1) {
      final items = _queue.toList();
      final item = items[index];
      final updated = item.copyWith(priority: newPriority);
      items[index] = updated;
      
      // Re-sort queue by priority
      items.sort((a, b) {
        final priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;
        return a.queuedAt.compareTo(b.queuedAt);
      });
      
      _queue.clear();
      _queue.addAll(items);
      
      await _updateQueueItem(updated);
      _notifyQueueUpdate();
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (_queue.isNotEmpty && _runningBuilds.length < _maxConcurrentBuilds) {
      final queueItem = _queue.removeFirst();
      
      if (queueItem.status == BuildQueueStatus.cancelled) {
        continue;
      }

      final running = queueItem.copyWith(
        status: BuildQueueStatus.running,
        startedAt: DateTime.now(),
      );
      _runningBuilds.add(running);
      await _updateQueueItem(running);
      
      _notifyQueueUpdate();
      _notifyRunningBuildsUpdate();

      // Start build asynchronously
      _executeBuild(running);
    }

    _isProcessing = false;
  }

  Future<void> _executeBuild(BuildQueueItem queueItem) async {
    try {
      final project = FlutterProject(
        id: queueItem.projectId,
        name: queueItem.projectName,
        path: '', // Will be retrieved from database if needed
        addedAt: DateTime.now(),
      );

      final buildHistory = await _buildService.startBuild(project, queueItem.buildConfig);
      
      final updated = queueItem.copyWith(
        buildHistoryId: buildHistory.id,
      );
      await _updateQueueItem(updated);

      // Listen for build completion
      _buildService.buildStream.listen((build) {
        if (build.id == buildHistory.id && build.isCompleted) {
          _onBuildCompleted(queueItem, build.status.name == 'success');
        }
      });
    } catch (e) {
      _onBuildCompleted(queueItem, false);
    }
  }

  Future<void> _onBuildCompleted(BuildQueueItem queueItem, bool success) async {
    _runningBuilds.removeWhere((item) => item.id == queueItem.id);
    
    final completed = queueItem.copyWith(
      status: success ? BuildQueueStatus.completed : BuildQueueStatus.failed,
      completedAt: DateTime.now(),
    );
    await _updateQueueItem(completed);
    
    _notifyRunningBuildsUpdate();
    
    // Process next item in queue
    _isProcessing = false;
    _processQueue();
  }

  Future<List<BuildQueueItem>> getQueueHistory({int limit = 50}) async {
    final results = await _db.query(
      'build_queue',
      orderBy: 'queued_at DESC',
      limit: limit,
    );
    return results.map((data) => _mapToQueueItem(data)).toList();
  }

  Future<void> clearCompletedItems() async {
    await _db.delete(
      'build_queue',
      where: 'status IN (?, ?)',
      whereArgs: ['completed', 'failed', 'cancelled'],
    );
  }

  void _notifyQueueUpdate() {
    _queueStreamController.add(_queue.toList());
  }

  void _notifyRunningBuildsUpdate() {
    _runningBuildsStreamController.add(_runningBuilds.toList());
  }

  Future<void> _saveQueueItem(BuildQueueItem item) async {
    await _db.insert('build_queue', _queueItemToMap(item));
  }

  Future<void> _updateQueueItem(BuildQueueItem item) async {
    await _db.update(
      'build_queue',
      _queueItemToMap(item),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  BuildQueueItem _mapToQueueItem(Map<String, dynamic> data) {
    return BuildQueueItem(
      id: data['id'] as String,
      projectId: data['project_id'] as String,
      projectName: data['project_name'] as String,
      buildConfig: BuildConfig.fromJson(jsonDecode(data['build_config'] as String)),
      queuedAt: DateTime.fromMillisecondsSinceEpoch(data['queued_at'] as int),
      startedAt: data['started_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['started_at'] as int)
          : null,
      completedAt: data['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['completed_at'] as int)
          : null,
      status: BuildQueueStatus.values.firstWhere((e) => e.name == data['status']),
      priority: data['priority'] as int,
      buildHistoryId: data['build_history_id'] as String?,
    );
  }

  Map<String, dynamic> _queueItemToMap(BuildQueueItem item) {
    return {
      'id': item.id,
      'project_id': item.projectId,
      'project_name': item.projectName,
      'build_config': jsonEncode(item.buildConfig.toJson()),
      'queued_at': item.queuedAt.millisecondsSinceEpoch,
      'started_at': item.startedAt?.millisecondsSinceEpoch,
      'completed_at': item.completedAt?.millisecondsSinceEpoch,
      'status': item.status.name,
      'priority': item.priority,
      'build_history_id': item.buildHistoryId,
    };
  }

  void dispose() {
    _queueStreamController.close();
    _runningBuildsStreamController.close();
  }
}
