import 'package:flutter_test/flutter_test.dart';
import 'package:drop_xide/utils/exceptions.dart';

void main() {
  group('AppException', () {
    test('should create an app exception with message', () {
      final exception = AppException(message: 'Test error');
      expect(exception.message, 'Test error');
      expect(exception.details, isNull);
    });

    test('should create an app exception with details', () {
      final exception = AppException(
        message: 'Test error',
        details: 'Error details',
      );
      expect(exception.message, 'Test error');
      expect(exception.details, 'Error details');
    });

    test('should format toString correctly', () {
      final exception = AppException(
        message: 'Test error',
        details: 'Error details',
      );
      final str = exception.toString();
      expect(str, contains('Test error'));
      expect(str, contains('Error details'));
    });
  });

  group('ProjectNotFoundException', () {
    test('should create with project ID', () {
      final exception = ProjectNotFoundException('project-123');
      expect(exception.message, 'Project not found');
      expect(exception.details, contains('project-123'));
    });
  });

  group('InvalidFlutterProjectException', () {
    test('should create with path', () {
      final exception = InvalidFlutterProjectException('/test/path');
      expect(exception.message, 'Invalid Flutter project');
      expect(exception.details, contains('/test/path'));
    });
  });

  group('FlutterSdkNotFoundException', () {
    test('should create with default message', () {
      final exception = FlutterSdkNotFoundException();
      expect(exception.message, 'Flutter SDK not found');
      expect(exception.details, isNotNull);
    });
  });

  group('BuildFailedException', () {
    test('should create with reason', () {
      final exception = BuildFailedException('Build failed due to error');
      expect(exception.message, 'Build failed');
      expect(exception.details, 'Build failed due to error');
    });
  });
}
