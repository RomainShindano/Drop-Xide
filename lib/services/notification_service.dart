import 'dart:io';

import '../models/build_history.dart';
import '../utils/logger.dart';

/// Desktop notifications via macOS Notification Center (osascript).
///
/// Avoids the `local_notifier` plugin, which does not support Swift Package
/// Manager and breaks Xcode/Xcode Cloud with:
///   Unable to resolve module dependency: 'local_notifier'
class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  final _logger = AppLogger();

  NotificationService._internal();

  Future<void> initialize() async {
    // No plugin setup required for osascript notifications.
  }

  Future<void> showBuildCompleted(BuildHistory build) async {
    await _show(
      title: 'Build Completed',
      body: '${build.projectName} built successfully',
    );
  }

  Future<void> showBuildFailed(BuildHistory build) async {
    await _show(
      title: 'Build Failed',
      body: '${build.projectName} build failed',
    );
  }

  Future<void> showAllBuildsCompleted(int successCount, int failedCount) async {
    await _show(
      title: 'All Builds Completed',
      body: '$successCount succeeded, $failedCount failed',
    );
  }

  Future<void> showQueueProgress(int completed, int total) async {
    await _show(
      title: 'Build Queue Progress',
      body: '$completed of $total builds completed',
      silent: true,
    );
  }

  Future<void> _show({
    required String title,
    required String body,
    bool silent = false,
  }) async {
    if (!Platform.isMacOS) {
      return;
    }

    try {
      final escapedTitle = _escapeAppleScript(title);
      final escapedBody = _escapeAppleScript(body);
      final soundClause = silent ? '' : ' sound name "Glass"';
      final script =
          'display notification "$escapedBody" with title "$escapedTitle"$soundClause';

      final result = await Process.run('osascript', ['-e', script]);
      if (result.exitCode != 0) {
        _logger.error(
          'Failed to show notification: ${result.stderr}',
        );
      }
    } catch (e) {
      _logger.error('Failed to show notification', e);
    }
  }

  String _escapeAppleScript(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', ' ');
  }
}
