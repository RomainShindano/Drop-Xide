import 'package:json_annotation/json_annotation.dart';
import 'flutter_project.dart';

part 'build_queue_item.g.dart';

@JsonSerializable()
class BuildQueueItem {
  final String id;
  final String projectId;
  final String projectName;
  final BuildConfig buildConfig;
  final DateTime queuedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final BuildQueueStatus status;
  final int priority;
  final String? buildHistoryId;

  BuildQueueItem({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.buildConfig,
    required this.queuedAt,
    this.startedAt,
    this.completedAt,
    required this.status,
    this.priority = 0,
    this.buildHistoryId,
  });

  factory BuildQueueItem.fromJson(Map<String, dynamic> json) =>
      _$BuildQueueItemFromJson(json);

  Map<String, dynamic> toJson() => _$BuildQueueItemToJson(this);

  BuildQueueItem copyWith({
    String? id,
    String? projectId,
    String? projectName,
    BuildConfig? buildConfig,
    DateTime? queuedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    BuildQueueStatus? status,
    int? priority,
    String? buildHistoryId,
  }) {
    return BuildQueueItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      buildConfig: buildConfig ?? this.buildConfig,
      queuedAt: queuedAt ?? this.queuedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      buildHistoryId: buildHistoryId ?? this.buildHistoryId,
    );
  }

  Duration? get waitTime {
    final start = startedAt ?? DateTime.now();
    return start.difference(queuedAt);
  }
}

enum BuildQueueStatus {
  queued,
  running,
  completed,
  failed,
  cancelled,
}
