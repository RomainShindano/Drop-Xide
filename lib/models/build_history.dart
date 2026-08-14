import 'package:json_annotation/json_annotation.dart';
import 'flutter_project.dart';

part 'build_history.g.dart';

@JsonSerializable()
class BuildHistory {
  final String id;
  final String projectId;
  final String projectName;
  final BuildConfig buildConfig;
  final DateTime startedAt;
  final DateTime? completedAt;
  final BuildStatus status;
  final String? outputPath;
  final String? errorMessage;
  final List<String> logs;

  BuildHistory({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.buildConfig,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.outputPath,
    this.errorMessage,
    this.logs = const [],
  });

  factory BuildHistory.fromJson(Map<String, dynamic> json) =>
      _$BuildHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$BuildHistoryToJson(this);

  BuildHistory copyWith({
    String? id,
    String? projectId,
    String? projectName,
    BuildConfig? buildConfig,
    DateTime? startedAt,
    DateTime? completedAt,
    BuildStatus? status,
    String? outputPath,
    String? errorMessage,
    List<String>? logs,
  }) {
    return BuildHistory(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      buildConfig: buildConfig ?? this.buildConfig,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      outputPath: outputPath ?? this.outputPath,
      errorMessage: errorMessage ?? this.errorMessage,
      logs: logs ?? this.logs,
    );
  }

  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  bool get isCompleted => status == BuildStatus.success || status == BuildStatus.failed;
}

enum BuildStatus {
  pending,
  running,
  success,
  failed,
  cancelled,
}
