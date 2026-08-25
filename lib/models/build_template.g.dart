// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildTemplate _$BuildTemplateFromJson(Map<String, dynamic> json) =>
    BuildTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      buildConfig: BuildConfig.fromJson(json['buildConfig'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] == null
          ? null
          : DateTime.parse(json['lastUsedAt'] as String),
      usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );

Map<String, dynamic> _$BuildTemplateToJson(BuildTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'buildConfig': instance.buildConfig.toJson(),
      'createdAt': instance.createdAt.toIso8601String(),
      'lastUsedAt': instance.lastUsedAt?.toIso8601String(),
      'usageCount': instance.usageCount,
      'isFavorite': instance.isFavorite,
    };
