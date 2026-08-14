// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_service_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GoogleServiceAccount _$GoogleServiceAccountFromJson(
  Map<String, dynamic> json,
) => GoogleServiceAccount(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  projectId: json['projectId'] as String,
  addedAt: DateTime.parse(json['addedAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$GoogleServiceAccountToJson(
  GoogleServiceAccount instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'projectId': instance.projectId,
  'addedAt': instance.addedAt.toIso8601String(),
  'isActive': instance.isActive,
};

PublishConfig _$PublishConfigFromJson(Map<String, dynamic> json) =>
    PublishConfig(
      serviceAccountId: json['serviceAccountId'] as String,
      track: $enumDecode(_$ReleaseTrackEnumMap, json['track']),
      releaseNotes: json['releaseNotes'] as String,
      userFraction: (json['userFraction'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PublishConfigToJson(PublishConfig instance) =>
    <String, dynamic>{
      'serviceAccountId': instance.serviceAccountId,
      'track': _$ReleaseTrackEnumMap[instance.track]!,
      'releaseNotes': instance.releaseNotes,
      'userFraction': instance.userFraction,
    };

const _$ReleaseTrackEnumMap = {
  ReleaseTrack.internal: 'internal',
  ReleaseTrack.alpha: 'alpha',
  ReleaseTrack.beta: 'beta',
  ReleaseTrack.production: 'production',
};
