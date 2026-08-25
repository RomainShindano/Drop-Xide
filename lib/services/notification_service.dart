import 'package:local_notifier/local_notifier.dart';
import '../models/build_history.dart';
import '../utils/logger.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  final _logger = AppLogger();

  NotificationService._internal();

  Future<void> initialize() async {
    try {
      await localNotifier.setup(
        appName: 'DropXide',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
    } catch (e) {
      _logger.error('Failed to initialize notifications', e);
    }
  }

  Future<void> showBuildCompleted(BuildHistory build) async {
    try {
      final notification = LocalNotification(
        title: 'Build Completed',
        body: '${build.projectName} built successfully',
        silent: false,
      );
      await notification.show();
    } catch (e) {
      _logger.error('Failed to show notification', e);
    }
  }

  Future<void> showBuildFailed(BuildHistory build) async {
    try {
      final notification = LocalNotification(
        title: 'Build Failed',
        body: '${build.projectName} build failed',
        silent: false,
      );
      await notification.show();
    } catch (e) {
      _logger.error('Failed to show notification', e);
    }
  }

  Future<void> showAllBuildsCompleted(int successCount, int failedCount) async {
    try {
      final notification = LocalNotification(
        title: 'All Builds Completed',
        body: '$successCount succeeded, $failedCount failed',
        silent: false,
      );
      await notification.show();
    } catch (e) {
      _logger.error('Failed to show notification', e);
    }
  }

  Future<void> showQueueProgress(int completed, int total) async {
    try {
      final notification = LocalNotification(
        title: 'Build Queue Progress',
        body: '$completed of $total builds completed',
        silent: true,
      );
      await notification.show();
    } catch (e) {
      _logger.error('Failed to show notification', e);
    }
  }
}
