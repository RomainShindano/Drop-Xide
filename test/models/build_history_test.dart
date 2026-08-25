import 'package:flutter_test/flutter_test.dart';
import 'package:drop_xide/models/build_history.dart';
import 'package:drop_xide/models/flutter_project.dart';

void main() {
  group('BuildHistory', () {
    test('should create a build history', () {
      final buildConfig = BuildConfig(
        mode: BuildMode.release,
        platform: BuildPlatform.android,
      );

      final history = BuildHistory(
        id: '123',
        buildNumber: 1,
        projectId: 'project-123',
        projectName: 'Test Project',
        buildConfig: buildConfig,
        startedAt: DateTime.now(),
        status: BuildStatus.success,
      );

      expect(history.id, '123');
      expect(history.projectId, 'project-123');
      expect(history.projectName, 'Test Project');
      expect(history.status, BuildStatus.success);
    });

    test('should calculate duration', () {
      final startedAt = DateTime(2024, 1, 1, 10, 0, 0);
      final completedAt = DateTime(2024, 1, 1, 10, 5, 30);

      final history = BuildHistory(
        id: '123',
        buildNumber: 1,
        projectId: 'project-123',
        projectName: 'Test Project',
        buildConfig: BuildConfig(
          mode: BuildMode.release,
          platform: BuildPlatform.android,
        ),
        startedAt: startedAt,
        completedAt: completedAt,
        status: BuildStatus.success,
      );

      expect(history.duration, isNotNull);
      expect(history.duration!.inMinutes, 5);
      expect(history.duration!.inSeconds, 330);
    });

    test('should check if build is completed', () {
      final successBuild = BuildHistory(
        id: '123',
        buildNumber: 1,
        projectId: 'project-123',
        projectName: 'Test Project',
        buildConfig: BuildConfig(
          mode: BuildMode.release,
          platform: BuildPlatform.android,
        ),
        startedAt: DateTime.now(),
        status: BuildStatus.success,
      );

      final runningBuild = successBuild.copyWith(status: BuildStatus.running);
      final failedBuild = successBuild.copyWith(status: BuildStatus.failed);

      expect(successBuild.isCompleted, true);
      expect(failedBuild.isCompleted, true);
      expect(runningBuild.isCompleted, false);
    });

    test('should convert to and from JSON', () {
      final history = BuildHistory(
        id: '123',
        buildNumber: 1,
        projectId: 'project-123',
        projectName: 'Test Project',
        buildConfig: BuildConfig(
          mode: BuildMode.release,
          platform: BuildPlatform.android,
        ),
        startedAt: DateTime(2024, 1, 1),
        status: BuildStatus.success,
        logs: ['log1', 'log2'],
      );

      final json = history.toJson();
      final fromJson = BuildHistory.fromJson(json);

      expect(fromJson.id, history.id);
      expect(fromJson.projectId, history.projectId);
      expect(fromJson.projectName, history.projectName);
      expect(fromJson.status, history.status);
      expect(fromJson.logs, history.logs);
    });
  });
}
