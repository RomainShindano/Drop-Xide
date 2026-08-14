class AppException implements Exception {
  final String message;
  final String? details;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.details,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AppException: $message');
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    return buffer.toString();
  }
}

class ProjectNotFoundException extends AppException {
  ProjectNotFoundException(String projectId)
      : super(
          message: 'Project not found',
          details: 'Project with ID "$projectId" does not exist',
        );
}

class InvalidFlutterProjectException extends AppException {
  InvalidFlutterProjectException(String path)
      : super(
          message: 'Invalid Flutter project',
          details: 'The directory "$path" is not a valid Flutter project',
        );
}

class FlutterSdkNotFoundException extends AppException {
  FlutterSdkNotFoundException()
      : super(
          message: 'Flutter SDK not found',
          details: 'Please install Flutter SDK and add it to your PATH',
        );
}

class BuildFailedException extends AppException {
  BuildFailedException(String reason, {dynamic originalError, StackTrace? stackTrace})
      : super(
          message: 'Build failed',
          details: reason,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class GooglePlayServiceException extends AppException {
  GooglePlayServiceException(String reason, {dynamic originalError, StackTrace? stackTrace})
      : super(
          message: 'Google Play service error',
          details: reason,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class ServiceAccountNotFoundException extends AppException {
  ServiceAccountNotFoundException(String accountId)
      : super(
          message: 'Service account not found',
          details: 'Service account with ID "$accountId" does not exist',
        );
}
