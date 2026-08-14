import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../providers/build_provider.dart';
import '../models/build_history.dart';

class BuildHistoryWidget extends StatelessWidget {
  const BuildHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BuildProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadBuildHistory(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.buildHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 100, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  'No Build History',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text('Your build history will appear here'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.buildHistory.length,
          itemBuilder: (context, index) {
            final build = provider.buildHistory[index];
            return _BuildHistoryCard(build: build);
          },
        );
      },
    );
  }
}

class _BuildHistoryCard extends StatelessWidget {
  final BuildHistory build;

  const _BuildHistoryCard({required this.build});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: build.outputPath != null ? () => _openOutputFolder(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusIcon(status: build.status),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          build.projectName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${build.buildConfig.platform.name.toUpperCase()} - ${build.buildConfig.mode.name.toUpperCase()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: build.status),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: DateFormat('MMM d, y HH:mm').format(build.startedAt),
                  ),
                  if (build.duration != null)
                    _InfoChip(
                      icon: Icons.timer,
                      label: _formatDuration(build.duration!),
                    ),
                  if (build.buildConfig.flavor != null)
                    _InfoChip(
                      icon: Icons.label,
                      label: build.buildConfig.flavor!,
                    ),
                ],
              ),
              if (build.outputPath != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.folder_open, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        build.outputPath!,
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (build.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          build.errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
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
        ),
      ),
    );
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

  void _openOutputFolder(BuildContext context) async {
    if (build.outputPath == null) return;

    try {
      if (Platform.isMacOS) {
        await Process.run('open', [build.outputPath!]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [build.outputPath!]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [build.outputPath!]);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _StatusIcon extends StatelessWidget {
  final BuildStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case BuildStatus.success:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case BuildStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
      case BuildStatus.running:
        icon = Icons.sync;
        color = Colors.blue;
        break;
      case BuildStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.orange;
        break;
      case BuildStatus.pending:
        icon = Icons.pending;
        color = Colors.grey;
        break;
    }

    return Icon(icon, color: color, size: 32);
  }
}

class _StatusBadge extends StatelessWidget {
  final BuildStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case BuildStatus.success:
        color = Colors.green;
        label = 'SUCCESS';
        break;
      case BuildStatus.failed:
        color = Colors.red;
        label = 'FAILED';
        break;
      case BuildStatus.running:
        color = Colors.blue;
        label = 'RUNNING';
        break;
      case BuildStatus.cancelled:
        color = Colors.orange;
        label = 'CANCELLED';
        break;
      case BuildStatus.pending:
        color = Colors.grey;
        label = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
