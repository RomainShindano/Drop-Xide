import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/publish_history.dart';
import '../models/google_service_account.dart';
import '../services/google_play_service.dart';
import '../services/database_service.dart';
import 'dart:convert';

class PublishProvider extends ChangeNotifier {
  final GooglePlayService _playService = GooglePlayService();
  final DatabaseService _db = DatabaseService.instance;
  final _uuid = const Uuid();

  List<PublishHistory> _publishHistory = [];
  PublishHistory? _currentPublish;
  bool _isLoading = false;
  String? _error;
  double _uploadProgress = 0.0;

  List<PublishHistory> get publishHistory => _publishHistory;
  PublishHistory? get currentPublish => _currentPublish;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;

  Future<void> loadPublishHistory({String? projectId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _db.query(
        'publish_history',
        where: projectId != null ? 'project_id = ?' : null,
        whereArgs: projectId != null ? [projectId] : null,
        orderBy: 'started_at DESC',
        limit: 50,
      );

      _publishHistory = results.map((data) => _mapToPublishHistory(data)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> publishToPlayStore({
    required String projectId,
    required String projectName,
    required String packageName,
    required String serviceAccountId,
    required String aabPath,
    required String versionName,
    required int versionCode,
    required ReleaseTrack track,
    required Map<String, String> releaseNotes,
    double? rolloutPercentage,
  }) async {
    _error = null;
    _uploadProgress = 0.0;

    final publishHistory = PublishHistory(
      id: _uuid.v4(),
      projectId: projectId,
      projectName: projectName,
      packageName: packageName,
      serviceAccountId: serviceAccountId,
      aabPath: aabPath,
      versionName: versionName,
      versionCode: versionCode,
      track: track,
      releaseNotes: releaseNotes,
      rolloutPercentage: rolloutPercentage,
      startedAt: DateTime.now(),
      status: PublishStatus.pending,
    );

    await _savePublishHistory(publishHistory);
    _currentPublish = publishHistory;
    _publishHistory.insert(0, publishHistory);
    notifyListeners();

    try {
      // Update status to uploading
      final uploading = publishHistory.copyWith(status: PublishStatus.uploading);
      await _updatePublishHistory(uploading);
      _currentPublish = uploading;
      _updateInList(uploading);

      // Simulate upload progress (in real implementation, this would track actual upload)
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        _uploadProgress = i / 10;
        notifyListeners();
      }

      // Call the service to upload
      await _playService.uploadToPlayStore(
        accountId: serviceAccountId,
        packageName: packageName,
        aabPath: aabPath,
        config: PublishConfig(
          serviceAccountId: serviceAccountId,
          track: track,
          releaseNotes: releaseNotes['en-US'] ?? '',
          userFraction: rolloutPercentage,
        ),
      );

      // Update status to processing
      final processing = uploading.copyWith(status: PublishStatus.processing);
      await _updatePublishHistory(processing);
      _currentPublish = processing;
      _updateInList(processing);

      // Wait for processing
      await Future.delayed(const Duration(seconds: 2));

      // Success
      final success = processing.copyWith(
        status: PublishStatus.success,
        completedAt: DateTime.now(),
      );
      await _updatePublishHistory(success);
      _currentPublish = success;
      _updateInList(success);

      _uploadProgress = 1.0;
      notifyListeners();
    } catch (e) {
      final failed = publishHistory.copyWith(
        status: PublishStatus.failed,
        completedAt: DateTime.now(),
        errorMessage: e.toString(),
      );
      await _updatePublishHistory(failed);
      _currentPublish = failed;
      _updateInList(failed);
      _error = e.toString();
      notifyListeners();
    }
  }

  void _updateInList(PublishHistory publish) {
    final index = _publishHistory.indexWhere((p) => p.id == publish.id);
    if (index != -1) {
      _publishHistory[index] = publish;
      notifyListeners();
    }
  }

  Future<void> _savePublishHistory(PublishHistory publish) async {
    await _db.insert('publish_history', _publishHistoryToMap(publish));
  }

  Future<void> _updatePublishHistory(PublishHistory publish) async {
    await _db.update(
      'publish_history',
      _publishHistoryToMap(publish),
      where: 'id = ?',
      whereArgs: [publish.id],
    );
  }

  PublishHistory _mapToPublishHistory(Map<String, dynamic> data) {
    return PublishHistory(
      id: data['id'] as String,
      projectId: data['project_id'] as String,
      projectName: data['project_name'] as String,
      packageName: data['package_name'] as String,
      serviceAccountId: data['service_account_id'] as String,
      aabPath: data['aab_path'] as String,
      versionName: data['version_name'] as String,
      versionCode: data['version_code'] as int,
      track: ReleaseTrack.values.firstWhere((e) => e.name == data['track']),
      releaseNotes: Map<String, String>.from(jsonDecode(data['release_notes'] as String)),
      rolloutPercentage: data['rollout_percentage'] as double?,
      startedAt: DateTime.fromMillisecondsSinceEpoch(data['started_at'] as int),
      completedAt: data['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['completed_at'] as int)
          : null,
      status: PublishStatus.values.firstWhere((e) => e.name == data['status']),
      errorMessage: data['error_message'] as String?,
    );
  }

  Map<String, dynamic> _publishHistoryToMap(PublishHistory publish) {
    return {
      'id': publish.id,
      'project_id': publish.projectId,
      'project_name': publish.projectName,
      'package_name': publish.packageName,
      'service_account_id': publish.serviceAccountId,
      'aab_path': publish.aabPath,
      'version_name': publish.versionName,
      'version_code': publish.versionCode,
      'track': publish.track.name,
      'release_notes': jsonEncode(publish.releaseNotes),
      'rollout_percentage': publish.rolloutPercentage,
      'started_at': publish.startedAt.millisecondsSinceEpoch,
      'completed_at': publish.completedAt?.millisecondsSinceEpoch,
      'status': publish.status.name,
      'error_message': publish.errorMessage,
    };
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetCurrentPublish() {
    _currentPublish = null;
    _uploadProgress = 0.0;
    notifyListeners();
  }
}
