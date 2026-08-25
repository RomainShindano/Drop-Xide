import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/build_provider.dart';
import '../models/build_queue_item.dart';
import 'ui/macos_polish.dart';
import 'ui/sleek_button.dart';

class BuildQueueWidget extends StatelessWidget {
  const BuildQueueWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BuildProvider>(
      builder: (context, provider, child) {
        final queueItems = provider.queueItems;
        final runningBuilds = provider.runningBuilds;

        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionHeader(
                  title: 'Build Queue',
                  subtitle: 'Manage queued and running builds',
                ),
                _ConcurrentBuildsSetting(
                  current: provider.maxConcurrentBuilds,
                  onChanged: (value) {
                    provider.setMaxConcurrentBuilds(value);
                  },
                ),
              ],
            ),
            if (runningBuilds.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Running Builds', style: context.dxSectionLabel),
              const SizedBox(height: 8),
              ...runningBuilds.map((item) => _QueueItemCard(
                    item: item,
                    isRunning: true,
                    onCancel: () => provider.cancelQueueItem(item.id),
                    onPriorityChange: null,
                  )),
            ],
            if (queueItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Queued Builds', style: context.dxSectionLabel),
              const SizedBox(height: 8),
              ...queueItems.map((item) => _QueueItemCard(
                    item: item,
                    isRunning: false,
                    onCancel: () => provider.cancelQueueItem(item.id),
                    onPriorityChange: (priority) =>
                        provider.changeQueuePriority(item.id, priority),
                  )),
            ],
            if (queueItems.isEmpty && runningBuilds.isEmpty) ...[
              const SizedBox(height: 100),
              Center(
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.list_bullet,
                      size: 64,
                      color: MacosColors.systemGrayColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text('Queue is Empty', style: context.dxTitle),
                    const SizedBox(height: 8),
                    Text(
                      'Queue builds to run them automatically',
                      textAlign: TextAlign.center,
                      style: context.dxCaption,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _QueueItemCard extends StatelessWidget {
  final BuildQueueItem item;
  final bool isRunning;
  final VoidCallback onCancel;
  final void Function(int priority)? onPriorityChange;

  const _QueueItemCard({
    required this.item,
    required this.isRunning,
    required this.onCancel,
    this.onPriorityChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusIcon(status: item.status, isRunning: isRunning),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.projectName, style: context.dxTitle),
                      const SizedBox(height: 2),
                      Text(
                        '${item.buildConfig.platform.name} - ${item.buildConfig.mode.name}',
                        style: context.dxCaption,
                      ),
                    ],
                  ),
                ),
                if (!isRunning && onPriorityChange != null)
                  MacosPopupButton<int>(
                    value: item.priority,
                    onChanged: (value) {
                      if (value != null) onPriorityChange!(value);
                    },
                    items: [
                      MacosPopupMenuItem(
                        value: 0,
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.arrowtriangle_down,
                                size: 12),
                            SizedBox(width: 6),
                            Text('Low'),
                          ],
                        ),
                      ),
                      MacosPopupMenuItem(
                        value: 5,
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.minus, size: 12),
                            SizedBox(width: 6),
                            Text('Normal'),
                          ],
                        ),
                      ),
                      MacosPopupMenuItem(
                        value: 10,
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.arrowtriangle_up, size: 12),
                            SizedBox(width: 6),
                            Text('High'),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 8),
                MacosIconButton(
                  icon: const Icon(CupertinoIcons.xmark_circle, size: 16),
                  onPressed: onCancel,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: CupertinoIcons.time,
                  label: 'Queued ${_formatTime(item.queuedAt)}',
                ),
                if (item.startedAt != null)
                  _InfoChip(
                    icon: CupertinoIcons.play_fill,
                    label: 'Started ${_formatTime(item.startedAt!)}',
                  ),
                if (item.waitTime != null && item.status == BuildQueueStatus.queued)
                  _InfoChip(
                    icon: CupertinoIcons.timer,
                    label: 'Waiting ${_formatDuration(item.waitTime!)}',
                  ),
                if (item.buildConfig.flavor != null)
                  _InfoChip(
                    icon: CupertinoIcons.tag,
                    label: item.buildConfig.flavor!,
                  ),
              ],
            ),
            if (isRunning) ...[
              const SizedBox(height: 12),
              const Center(child: ProgressCircle(radius: 8)),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm:ss').format(time);
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

class _StatusIcon extends StatelessWidget {
  final BuildQueueStatus status;
  final bool isRunning;

  const _StatusIcon({required this.status, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    if (isRunning) {
      icon = CupertinoIcons.arrow_clockwise;
      color = MacosColors.systemBlueColor;
    } else {
      switch (status) {
        case BuildQueueStatus.queued:
          icon = CupertinoIcons.clock;
          color = MacosColors.systemGrayColor;
          break;
        case BuildQueueStatus.running:
          icon = CupertinoIcons.arrow_clockwise;
          color = MacosColors.systemBlueColor;
          break;
        case BuildQueueStatus.completed:
          icon = CupertinoIcons.check_mark_circled_solid;
          color = MacosColors.systemGreenColor;
          break;
        case BuildQueueStatus.failed:
          icon = CupertinoIcons.exclamationmark_triangle_fill;
          color = MacosColors.systemRedColor;
          break;
        case BuildQueueStatus.cancelled:
          icon = CupertinoIcons.xmark_circle_fill;
          color = MacosColors.systemOrangeColor;
          break;
      }
    }

    return Icon(icon, color: color, size: 28);
  }
}

class _ConcurrentBuildsSetting extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;

  const _ConcurrentBuildsSetting({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MacosColors.systemGrayColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.slider_horizontal_3, size: 14),
          const SizedBox(width: 8),
          Text('Concurrent:', style: context.dxCaption),
          const SizedBox(width: 8),
          MacosPopupButton<int>(
            value: current,
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
            items: List.generate(10, (i) => i + 1)
                .map((n) => MacosPopupMenuItem(
                      value: n,
                      child: Text('$n'),
                    ))
                .toList(),
          ),
        ],
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
          Icon(icon, size: 12, color: MacosColors.secondaryLabelColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.dxCaption,
          ),
        ],
      ),
    );
  }
}
