import 'package:json_annotation/json_annotation.dart';

part 'flutter_project.g.dart';

@JsonSerializable()
class FlutterProject {
  final String id;
  final String name;
  final String path;
  final String? description;
  final DateTime addedAt;
  final DateTime? lastBuildAt;
  final BuildConfig? lastBuildConfig;

  FlutterProject({
    required this.id,
    required this.name,
    required this.path,
    this.description,
    required this.addedAt,
    this.lastBuildAt,
    this.lastBuildConfig,
  });

  factory FlutterProject.fromJson(Map<String, dynamic> json) =>
      _$FlutterProjectFromJson(json);

  Map<String, dynamic> toJson() => _$FlutterProjectToJson(this);

  FlutterProject copyWith({
    String? id,
    String? name,
    String? path,
    String? description,
    DateTime? addedAt,
    DateTime? lastBuildAt,
    BuildConfig? lastBuildConfig,
  }) {
    return FlutterProject(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      description: description ?? this.description,
      addedAt: addedAt ?? this.addedAt,
      lastBuildAt: lastBuildAt ?? this.lastBuildAt,
      lastBuildConfig: lastBuildConfig ?? this.lastBuildConfig,
    );
  }
}

@JsonSerializable()
class BuildConfig {
  final BuildMode mode;
  final BuildPlatform platform;
  final BuildType? buildType;
  final String? flavor;
  final String? branch;
  final bool obfuscate;
  final bool splitDebugInfo;

  BuildConfig({
    required this.mode,
    required this.platform,
    this.buildType,
    this.flavor,
    this.branch,
    this.obfuscate = false,
    this.splitDebugInfo = false,
  });

  factory BuildConfig.fromJson(Map<String, dynamic> json) =>
      _$BuildConfigFromJson(json);

  Map<String, dynamic> toJson() => _$BuildConfigToJson(this);

  /// Effective Android artifact type (defaults to APK).
  BuildType get effectiveBuildType {
    if (buildType != null) return buildType!;
    switch (platform) {
      case BuildPlatform.android:
        return BuildType.apk;
      case BuildPlatform.ios:
        return BuildType.ipa;
      default:
        return BuildType.apk;
    }
  }
}

enum BuildMode {
  debug,
  profile,
  release,
}

enum BuildPlatform {
  android,
  ios,
  web,
  linux,
  macos,
  windows,
}

enum BuildType {
  apk,
  appbundle,
  ipa,
}
