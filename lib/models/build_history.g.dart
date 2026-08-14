// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildHistory _$BuildHistoryFromJson(Map<String, dynamic> json) => BuildHistory(
  id: json['id'] as String,
  projectId: json['projectId'] as String,
  projectName: json['projectName'] as String,
  buildConfig: BuildConfig.fromJson(
    json['buildConfig'] as Map<String, dynamic>,
  ),
  startedAt: DateTime.parse(json['startedAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  status: $enumDecode(_$BuildStatusEnumMap, json['status']),
  outputPath: json['outputPath'] as String?,
  errorMessage: json['errorMessage'] as String?,
  logs:
      (json['logs'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$BuildHistoryToJson(BuildHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'projectName': instance.projectName,
      'buildConfig': instance.buildConfig,
      'startedAt': instance.startedAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'status': _$BuildStatusEnumMap[instance.status]!,
      'outputPath': instance.outputPath,
      'errorMessage': instance.errorMessage,
      'logs': instance.logs,
    };

const _$BuildStatusEnumMap = {
  BuildStatus.pending: 'pending',
  BuildStatus.running: 'running',
  BuildStatus.success: 'success',
  BuildStatus.failed: 'failed',
  BuildStatus.cancelled: 'cancelled',
};
