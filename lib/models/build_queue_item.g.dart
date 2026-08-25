// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_queue_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildQueueItem _$BuildQueueItemFromJson(Map<String, dynamic> json) =>
    BuildQueueItem(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      buildConfig: BuildConfig.fromJson(json['buildConfig'] as Map<String, dynamic>),
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      status: $enumDecode(_$BuildQueueStatusEnumMap, json['status']),
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      buildHistoryId: json['buildHistoryId'] as String?,
    );

Map<String, dynamic> _$BuildQueueItemToJson(BuildQueueItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'projectName': instance.projectName,
      'buildConfig': instance.buildConfig.toJson(),
      'queuedAt': instance.queuedAt.toIso8601String(),
      'startedAt': instance.startedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'status': _$BuildQueueStatusEnumMap[instance.status]!,
      'priority': instance.priority,
      'buildHistoryId': instance.buildHistoryId,
    };

const _$BuildQueueStatusEnumMap = {
  BuildQueueStatus.queued: 'queued',
  BuildQueueStatus.running: 'running',
  BuildQueueStatus.completed: 'completed',
  BuildQueueStatus.failed: 'failed',
  BuildQueueStatus.cancelled: 'cancelled',
};
