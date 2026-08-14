import 'package:json_annotation/json_annotation.dart';

part 'google_service_account.g.dart';

@JsonSerializable()
class GoogleServiceAccount {
  final String id;
  final String name;
  final String email;
  final String projectId;
  final DateTime addedAt;
  final bool isActive;

  GoogleServiceAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.projectId,
    required this.addedAt,
    this.isActive = true,
  });

  factory GoogleServiceAccount.fromJson(Map<String, dynamic> json) =>
      _$GoogleServiceAccountFromJson(json);

  Map<String, dynamic> toJson() => _$GoogleServiceAccountToJson(this);

  GoogleServiceAccount copyWith({
    String? id,
    String? name,
    String? email,
    String? projectId,
    DateTime? addedAt,
    bool? isActive,
  }) {
    return GoogleServiceAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      projectId: projectId ?? this.projectId,
      addedAt: addedAt ?? this.addedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

@JsonSerializable()
class PublishConfig {
  final String serviceAccountId;
  final ReleaseTrack track;
  final String releaseNotes;
  final double? userFraction;

  PublishConfig({
    required this.serviceAccountId,
    required this.track,
    required this.releaseNotes,
    this.userFraction,
  });

  factory PublishConfig.fromJson(Map<String, dynamic> json) =>
      _$PublishConfigFromJson(json);

  Map<String, dynamic> toJson() => _$PublishConfigToJson(this);
}

enum ReleaseTrack {
  internal,
  alpha,
  beta,
  production,
}
