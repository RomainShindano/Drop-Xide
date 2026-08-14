// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flutter_project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlutterProject _$FlutterProjectFromJson(Map<String, dynamic> json) =>
    FlutterProject(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      description: json['description'] as String?,
      addedAt: DateTime.parse(json['addedAt'] as String),
      lastBuildAt: json['lastBuildAt'] == null
          ? null
          : DateTime.parse(json['lastBuildAt'] as String),
      lastBuildConfig: json['lastBuildConfig'] == null
          ? null
          : BuildConfig.fromJson(
              json['lastBuildConfig'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$FlutterProjectToJson(FlutterProject instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'path': instance.path,
      'description': instance.description,
      'addedAt': instance.addedAt.toIso8601String(),
      'lastBuildAt': instance.lastBuildAt?.toIso8601String(),
      'lastBuildConfig': instance.lastBuildConfig,
    };

BuildConfig _$BuildConfigFromJson(Map<String, dynamic> json) => BuildConfig(
  mode: $enumDecode(_$BuildModeEnumMap, json['mode']),
  platform: $enumDecode(_$BuildPlatformEnumMap, json['platform']),
  flavor: json['flavor'] as String?,
  obfuscate: json['obfuscate'] as bool? ?? false,
  splitDebugInfo: json['splitDebugInfo'] as bool? ?? false,
);

Map<String, dynamic> _$BuildConfigToJson(BuildConfig instance) =>
    <String, dynamic>{
      'mode': _$BuildModeEnumMap[instance.mode]!,
      'platform': _$BuildPlatformEnumMap[instance.platform]!,
      'flavor': instance.flavor,
      'obfuscate': instance.obfuscate,
      'splitDebugInfo': instance.splitDebugInfo,
    };

const _$BuildModeEnumMap = {
  BuildMode.debug: 'debug',
  BuildMode.profile: 'profile',
  BuildMode.release: 'release',
};

const _$BuildPlatformEnumMap = {
  BuildPlatform.android: 'android',
  BuildPlatform.ios: 'ios',
  BuildPlatform.web: 'web',
  BuildPlatform.linux: 'linux',
  BuildPlatform.macos: 'macos',
  BuildPlatform.windows: 'windows',
};
