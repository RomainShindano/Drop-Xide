import 'package:flutter_test/flutter_test.dart';
import 'package:drop_xide/models/flutter_project.dart';

void main() {
  group('FlutterProject', () {
    test('should create a Flutter project', () {
      final project = FlutterProject(
        id: '123',
        name: 'Test Project',
        path: '/test/path',
        description: 'A test project',
        addedAt: DateTime.now(),
      );

      expect(project.id, '123');
      expect(project.name, 'Test Project');
      expect(project.path, '/test/path');
      expect(project.description, 'A test project');
    });

    test('should convert to and from JSON', () {
      final project = FlutterProject(
        id: '123',
        name: 'Test Project',
        path: '/test/path',
        description: 'A test project',
        addedAt: DateTime(2024, 1, 1),
      );

      final json = project.toJson();
      final fromJson = FlutterProject.fromJson(json);

      expect(fromJson.id, project.id);
      expect(fromJson.name, project.name);
      expect(fromJson.path, project.path);
      expect(fromJson.description, project.description);
    });

    test('should copy with modifications', () {
      final project = FlutterProject(
        id: '123',
        name: 'Test Project',
        path: '/test/path',
        addedAt: DateTime.now(),
      );

      final updated = project.copyWith(name: 'Updated Project');

      expect(updated.id, project.id);
      expect(updated.name, 'Updated Project');
      expect(updated.path, project.path);
    });
  });

  group('BuildConfig', () {
    test('should create a build config', () {
      final config = BuildConfig(
        mode: BuildMode.release,
        platform: BuildPlatform.android,
        flavor: 'production',
        obfuscate: true,
        splitDebugInfo: true,
      );

      expect(config.mode, BuildMode.release);
      expect(config.platform, BuildPlatform.android);
      expect(config.flavor, 'production');
      expect(config.obfuscate, true);
      expect(config.splitDebugInfo, true);
    });

    test('should convert to and from JSON', () {
      final config = BuildConfig(
        mode: BuildMode.release,
        platform: BuildPlatform.android,
      );

      final json = config.toJson();
      final fromJson = BuildConfig.fromJson(json);

      expect(fromJson.mode, config.mode);
      expect(fromJson.platform, config.platform);
    });
  });
}
