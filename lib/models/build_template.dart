import 'package:json_annotation/json_annotation.dart';
import 'flutter_project.dart';

part 'build_template.g.dart';

@JsonSerializable()
class BuildTemplate {
  final String id;
  final String name;
  final String? description;
  final BuildConfig buildConfig;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final int usageCount;
  final bool isFavorite;

  BuildTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.buildConfig,
    required this.createdAt,
    this.lastUsedAt,
    this.usageCount = 0,
    this.isFavorite = false,
  });

  factory BuildTemplate.fromJson(Map<String, dynamic> json) =>
      _$BuildTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$BuildTemplateToJson(this);

  BuildTemplate copyWith({
    String? id,
    String? name,
    String? description,
    BuildConfig? buildConfig,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? usageCount,
    bool? isFavorite,
  }) {
    return BuildTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      buildConfig: buildConfig ?? this.buildConfig,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
