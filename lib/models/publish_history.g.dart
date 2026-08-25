// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publish_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublishHistory _$PublishHistoryFromJson(Map<String, dynamic> json) =>
    PublishHistory(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      packageName: json['packageName'] as String,
      serviceAccountId: json['serviceAccountId'] as String,
      aabPath: json['aabPath'] as String,
      versionName: json['versionName'] as String,
      versionCode: (json['versionCode'] as num).toInt(),
      track: $enumDecode(_$ReleaseTrackEnumMap, json['track']),
      releaseNotes: Map<String, String>.from(json['releaseNotes'] as Map),
      rolloutPercentage: (json['rolloutPercentage'] as num?)?.toDouble(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      status: $enumDecode(_$PublishStatusEnumMap, json['status']),
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$PublishHistoryToJson(PublishHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'projectName': instance.projectName,
      'packageName': instance.packageName,
      'serviceAccountId': instance.serviceAccountId,
      'aabPath': instance.aabPath,
      'versionName': instance.versionName,
      'versionCode': instance.versionCode,
      'track': _$ReleaseTrackEnumMap[instance.track]!,
      'releaseNotes': instance.releaseNotes,
      'rolloutPercentage': instance.rolloutPercentage,
      'startedAt': instance.startedAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'status': _$PublishStatusEnumMap[instance.status]!,
      'errorMessage': instance.errorMessage,
    };

const _$ReleaseTrackEnumMap = {
  ReleaseTrack.internal: 'internal',
  ReleaseTrack.alpha: 'alpha',
  ReleaseTrack.beta: 'beta',
  ReleaseTrack.production: 'production',
};

const _$PublishStatusEnumMap = {
  PublishStatus.pending: 'pending',
  PublishStatus.uploading: 'uploading',
  PublishStatus.processing: 'processing',
  PublishStatus.success: 'success',
  PublishStatus.failed: 'failed',
  PublishStatus.cancelled: 'cancelled',
};
