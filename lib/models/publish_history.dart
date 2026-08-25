import 'package:json_annotation/json_annotation.dart';
import 'google_service_account.dart';

part 'publish_history.g.dart';

@JsonSerializable()
class PublishHistory {
  final String id;
  final String projectId;
  final String projectName;
  final String packageName;
  final String serviceAccountId;
  final String aabPath;
  final String versionName;
  final int versionCode;
  final ReleaseTrack track;
  final Map<String, String> releaseNotes;
  final double? rolloutPercentage;
  final DateTime startedAt;
  final DateTime? completedAt;
  final PublishStatus status;
  final String? errorMessage;

  PublishHistory({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.packageName,
    required this.serviceAccountId,
    required this.aabPath,
    required this.versionName,
    required this.versionCode,
    required this.track,
    required this.releaseNotes,
    this.rolloutPercentage,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.errorMessage,
  });

  factory PublishHistory.fromJson(Map<String, dynamic> json) =>
      _$PublishHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$PublishHistoryToJson(this);

  PublishHistory copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? packageName,
    String? serviceAccountId,
    String? aabPath,
    String? versionName,
    int? versionCode,
    ReleaseTrack? track,
    Map<String, String>? releaseNotes,
    double? rolloutPercentage,
    DateTime? startedAt,
    DateTime? completedAt,
    PublishStatus? status,
    String? errorMessage,
  }) {
    return PublishHistory(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      packageName: packageName ?? this.packageName,
      serviceAccountId: serviceAccountId ?? this.serviceAccountId,
      aabPath: aabPath ?? this.aabPath,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      track: track ?? this.track,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      rolloutPercentage: rolloutPercentage ?? this.rolloutPercentage,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  bool get isCompleted =>
      status == PublishStatus.success || status == PublishStatus.failed;
}

enum PublishStatus {
  pending,
  uploading,
  processing,
  success,
  failed,
  cancelled,
}
