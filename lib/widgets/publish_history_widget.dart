import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/publish_provider.dart';
import '../models/publish_history.dart';
import '../models/google_service_account.dart';
import 'ui/macos_polish.dart';

class PublishHistoryWidget extends StatelessWidget {
  const PublishHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PublishProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: ProgressCircle());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle,
                    size: 64, color: MacosColors.systemRedColor),
                const SizedBox(height: 16),
                Text('Error: ${provider.error}'),
                const SizedBox(height: 16),
                PushButton(
                  controlSize: ControlSize.large,
                  onPressed: () => provider.loadPublishHistory(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.publishHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.cloud_upload,
                  size: 100,
                  color: MacosColors.systemGrayColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No Publish History',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your Google Play Store publish history will appear here',
                  style: TextStyle(color: MacosColors.secondaryLabelColor),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.publishHistory.length,
          itemBuilder: (context, index) {
            final publish = provider.publishHistory[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PublishHistoryCard(publish: publish),
            );
          },
        );
      },
    );
  }
}

class _PublishHistoryCard extends StatelessWidget {
  final PublishHistory publish;

  const _PublishHistoryCard({required this.publish});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusIcon(status: publish.status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publish.projectName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      publish.packageName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: MacosColors.secondaryLabelColor,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: publish.status),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: CupertinoIcons.number,
                label: 'v${publish.versionName} (${publish.versionCode})',
              ),
              _InfoChip(
                icon: CupertinoIcons.arrow_branch,
                label: _getTrackLabel(publish.track),
              ),
              _InfoChip(
                icon: CupertinoIcons.calendar,
                label: DateFormat('MMM d, y HH:mm').format(publish.startedAt),
              ),
              if (publish.duration != null)
                _InfoChip(
                  icon: CupertinoIcons.timer,
                  label: _formatDuration(publish.duration!),
                ),
              if (publish.rolloutPercentage != null)
                _InfoChip(
                  icon: CupertinoIcons.chart_bar,
                  label: '${publish.rolloutPercentage!.toInt()}% rollout',
                ),
            ],
          ),
          if (publish.releaseNotes.isNotEmpty &&
              publish.releaseNotes['en-US']?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MacosColors.systemGrayColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(CupertinoIcons.doc_text, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Release Notes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    publish.releaseNotes['en-US']!,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          if (publish.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MacosColors.systemRedColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.exclamationmark_triangle,
                      size: 16, color: MacosColors.systemRedColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      publish.errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: MacosColors.systemRedColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getTrackLabel(ReleaseTrack track) {
    switch (track) {
      case ReleaseTrack.internal:
        return 'Internal';
      case ReleaseTrack.alpha:
        return 'Alpha';
      case ReleaseTrack.beta:
        return 'Beta';
      case ReleaseTrack.production:
        return 'Production';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

class _StatusIcon extends StatelessWidget {
  final PublishStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case PublishStatus.success:
        icon = CupertinoIcons.check_mark_circled_solid;
        color = MacosColors.systemGreenColor;
        break;
      case PublishStatus.failed:
        icon = CupertinoIcons.exclamationmark_triangle_fill;
        color = MacosColors.systemRedColor;
        break;
      case PublishStatus.uploading:
      case PublishStatus.processing:
        icon = CupertinoIcons.arrow_up_circle_fill;
        color = MacosColors.systemBlueColor;
        break;
      case PublishStatus.cancelled:
        icon = CupertinoIcons.xmark_circle_fill;
        color = MacosColors.systemOrangeColor;
        break;
      case PublishStatus.pending:
        icon = CupertinoIcons.clock_fill;
        color = MacosColors.systemGrayColor;
        break;
    }

    return Icon(icon, color: color, size: 32);
  }
}

class _StatusBadge extends StatelessWidget {
  final PublishStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case PublishStatus.success:
        color = MacosColors.systemGreenColor;
        label = 'SUCCESS';
        break;
      case PublishStatus.failed:
        color = MacosColors.systemRedColor;
        label = 'FAILED';
        break;
      case PublishStatus.uploading:
        color = MacosColors.systemBlueColor;
        label = 'UPLOADING';
        break;
      case PublishStatus.processing:
        color = MacosColors.systemBlueColor;
        label = 'PROCESSING';
        break;
      case PublishStatus.cancelled:
        color = MacosColors.systemOrangeColor;
        label = 'CANCELLED';
        break;
      case PublishStatus.pending:
        color = MacosColors.systemGrayColor;
        label = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MacosColors.systemGrayColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: MacosColors.secondaryLabelColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: MacosColors.secondaryLabelColor,
            ),
          ),
        ],
      ),
    );
  }
}
