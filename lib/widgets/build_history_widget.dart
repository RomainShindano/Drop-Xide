import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import '../providers/build_provider.dart';
import '../providers/project_provider.dart';
import '../models/build_history.dart';
import 'ui/macos_polish.dart';
import 'ui/sleek_button.dart';

class BuildHistoryWidget extends StatefulWidget {
  const BuildHistoryWidget({super.key});

  @override
  State<BuildHistoryWidget> createState() => _BuildHistoryWidgetState();
}

class _BuildHistoryWidgetState extends State<BuildHistoryWidget> {
  bool _filterToSelectedProject = true;
  String? _expandedId;
  String? _lastSelectedProjectId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final selectedId = context.read<ProjectProvider>().selectedProject?.id;
    if (selectedId != _lastSelectedProjectId) {
      _lastSelectedProjectId = selectedId;
      if (_filterToSelectedProject) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _reload();
        });
      }
    }
  }

  Future<void> _reload() async {
    final projectId = _filterToSelectedProject
        ? context.read<ProjectProvider>().selectedProject?.id
        : null;
    await context.read<BuildProvider>().loadBuildHistory(projectId: projectId);
  }

  @override
  Widget build(BuildContext context) {
    final selectedProject = context.watch<ProjectProvider>().selectedProject;

    return Consumer<BuildProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: ProgressCircle());
        }

        if (provider.error != null) {
          return EmptyState(
            icon: CupertinoIcons.exclamationmark_circle,
            title: 'Couldn’t load history',
            message: provider.error!,
            actionLabel: 'Retry',
            onAction: _reload,
          );
        }

        if (provider.buildHistory.isEmpty) {
          return EmptyState(
            icon: CupertinoIcons.clock,
            title: _filterToSelectedProject && selectedProject != null
                ? 'No builds for ${selectedProject.name}'
                : 'No builds yet',
            message: _filterToSelectedProject && selectedProject != null
                ? 'Run a build for this project, or show all projects.'
                : 'Successful and failed builds appear here with full logs.',
            actionLabel: _filterToSelectedProject && selectedProject != null
                ? 'Show all projects'
                : null,
            onAction: _filterToSelectedProject && selectedProject != null
                ? () {
                    setState(() => _filterToSelectedProject = false);
                    _reload();
                  }
                : null,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: SectionHeader(
                title: 'Builds & logs',
                subtitle: _filterToSelectedProject && selectedProject != null
                    ? '${provider.buildHistory.length} for ${selectedProject.name}'
                    : '${provider.buildHistory.length} across all projects',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedProject == null
                          ? 'All projects'
                          : 'Selected only',
                      style: MacosTheme.of(context).typography.caption1,
                    ),
                    const SizedBox(width: 8),
                    MacosSwitch(
                      value: _filterToSelectedProject && selectedProject != null,
                      onChanged: selectedProject == null
                          ? null
                          : (value) {
                              setState(() => _filterToSelectedProject = value);
                              _reload();
                            },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: provider.buildHistory.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final history = provider.buildHistory[index];
                  final expanded = _expandedId == history.id;
                  return _HistoryRow(
                    history: history,
                    expanded: expanded,
                    onToggleLogs: () {
                      setState(() {
                        _expandedId = expanded ? null : history.id;
                      });
                    },
                    onDelete: () =>
                        _confirmDelete(context, provider, history.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BuildProvider provider,
    String id,
  ) async {
    final confirm = await showMacosAlertDialog<bool>(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: const MacosIcon(
          CupertinoIcons.trash,
          size: 64,
          color: MacosColors.systemRedColor,
        ),
        title: Text(
          'Delete Build',
          style: MacosTheme.of(context).typography.headline,
        ),
        message: const Text(
          'Remove this build and its saved logs from history?',
          textAlign: TextAlign.center,
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          color: MacosColors.systemRedColor,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ),
    );

    if (confirm == true) {
      await provider.deleteBuildHistory(id);
      if (_expandedId == id) {
        setState(() => _expandedId = null);
      }
    }
  }
}

class _HistoryRow extends StatelessWidget {
  final BuildHistory history;
  final bool expanded;
  final VoidCallback onToggleLogs;
  final VoidCallback onDelete;

  const _HistoryRow({
    required this.history,
    required this.expanded,
    required this.onToggleLogs,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    final secondary = MacosColors.secondaryLabelColor.resolveFrom(context);
    final statusColor = _statusColor(history.status);
    final logCount = history.logs.length;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          HoverSurface(
            onTap: onToggleLogs,
            borderRadius: BorderRadius.circular(10),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: MacosIcon(
                          _statusIcon(history.status),
                          color: statusColor,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                history.projectName,
                                style: typography.headline.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.dxLabel,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: MacosColors.controlBackgroundColor
                                      .resolveFrom(context),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${history.buildNumber}',
                                  style: typography.caption2.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${history.buildConfig.platform.name.toUpperCase()} · ${history.buildConfig.mode.name}'
                            '${history.artifactPath != null ? " · ${history.artifactSizeFormatted}" : ""}',
                            style:
                                typography.caption1.copyWith(color: secondary),
                          ),
                        ],
                      ),
                    ),
                    StatusPill(
                      label: _statusLabel(history.status),
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    MacosIconButton(
                      icon: MacosIcon(
                        CupertinoIcons.trash,
                        color:
                            MacosColors.systemRedColor.withValues(alpha: 0.85),
                        size: 14,
                      ),
                      onPressed: onDelete,
                      boxConstraints: const BoxConstraints(
                        minHeight: 28,
                        minWidth: 28,
                        maxHeight: 28,
                        maxWidth: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  [
                    DateFormat('MMM d, y HH:mm').format(history.startedAt),
                    if (history.duration != null)
                      _formatDuration(history.duration!),
                    if (history.buildConfig.flavor != null)
                      history.buildConfig.flavor!,
                    '$logCount log line${logCount == 1 ? '' : 's'}',
                  ].join('  ·  '),
                  style: typography.caption1.copyWith(color: secondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SleekButton.label(
                      label: expanded ? 'Hide logs' : 'View logs',
                      size: SleekButtonSize.small,
                      secondary: true,
                      leadingIcon: expanded
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.doc_text,
                      onPressed: onToggleLogs,
                    ),
                    if (history.outputPath != null) ...[
                      const SizedBox(width: 8),
                      SleekButton.label(
                        label: 'Open output',
                        size: SleekButtonSize.small,
                        secondary: true,
                        leadingIcon: CupertinoIcons.folder,
                        onPressed: () => _openOutputFolder(context),
                      ),
                    ],
                    if (history.artifactPath != null && history.status == BuildStatus.success) ...[
                      const SizedBox(width: 8),
                      SleekButton.label(
                        label: 'View artifact',
                        size: SleekButtonSize.small,
                        secondary: false,
                        leadingIcon: CupertinoIcons.square_arrow_down,
                        onPressed: () => _revealArtifact(context),
                      ),
                    ],
                    const Spacer(),
                    MacosIcon(
                      expanded
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 12,
                      color: secondary,
                    ),
                  ],
                ),
                if (history.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    history.errorMessage!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.caption1.copyWith(
                      color: MacosColors.systemRedColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (expanded) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(12),
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: logCount == 0
                  ? Center(
                      child: Text(
                        'No logs were saved for this build.',
                        style: typography.caption1.copyWith(
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: logCount,
                      itemBuilder: (context, index) {
                        return Text(
                          history.logs[index],
                          style: const TextStyle(
                            fontFamily: 'Menlo',
                            fontSize: 11.5,
                            height: 1.4,
                            color: Color(0xFF32D74B),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(BuildStatus status) {
    switch (status) {
      case BuildStatus.success:
        return MacosColors.systemGreenColor;
      case BuildStatus.failed:
        return MacosColors.systemRedColor;
      case BuildStatus.running:
        return MacosColors.systemBlueColor;
      case BuildStatus.cancelled:
        return MacosColors.systemOrangeColor;
      case BuildStatus.pending:
        return MacosColors.systemGrayColor;
    }
  }

  IconData _statusIcon(BuildStatus status) {
    switch (status) {
      case BuildStatus.success:
        return CupertinoIcons.check_mark_circled_solid;
      case BuildStatus.failed:
        return CupertinoIcons.xmark_circle_fill;
      case BuildStatus.running:
        return CupertinoIcons.arrow_2_circlepath;
      case BuildStatus.cancelled:
        return CupertinoIcons.stop_circle_fill;
      case BuildStatus.pending:
        return CupertinoIcons.clock_fill;
    }
  }

  String _statusLabel(BuildStatus status) {
    switch (status) {
      case BuildStatus.success:
        return 'Success';
      case BuildStatus.failed:
        return 'Failed';
      case BuildStatus.running:
        return 'Running';
      case BuildStatus.cancelled:
        return 'Cancelled';
      case BuildStatus.pending:
        return 'Pending';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    }
    return '${duration.inSeconds}s';
  }

  Future<void> _openOutputFolder(BuildContext context) async {
    if (history.outputPath == null) return;

    try {
      if (Platform.isMacOS) {
        await Process.run('open', [history.outputPath!]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [history.outputPath!]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [history.outputPath!]);
      }
    } catch (e) {
      if (!context.mounted) return;
      await showMacosAlertDialog(
        context: context,
        builder: (_) => MacosAlertDialog(
          appIcon: const MacosIcon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 64,
            color: MacosColors.systemOrangeColor,
          ),
          title: Text(
            'Could Not Open Folder',
            style: MacosTheme.of(context).typography.headline,
          ),
          message: Text('$e', textAlign: TextAlign.center),
          primaryButton: PushButton(
            controlSize: ControlSize.large,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ),
      );
    }
  }

  Future<void> _revealArtifact(BuildContext context) async {
    if (history.artifactPath == null) return;

    try {
      final file = File(history.artifactPath!);
      if (!await file.exists()) {
        if (!context.mounted) return;
        await showMacosAlertDialog(
          context: context,
          builder: (_) => MacosAlertDialog(
            appIcon: const MacosIcon(
              CupertinoIcons.exclamationmark_triangle_fill,
              size: 64,
              color: MacosColors.systemOrangeColor,
            ),
            title: Text(
              'Artifact Not Found',
              style: MacosTheme.of(context).typography.headline,
            ),
            message: const Text(
              'The build artifact file no longer exists.',
              textAlign: TextAlign.center,
            ),
            primaryButton: PushButton(
              controlSize: ControlSize.large,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ),
        );
        return;
      }

      if (Platform.isMacOS) {
        await Process.run('open', ['-R', history.artifactPath!]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', history.artifactPath!]);
      } else if (Platform.isLinux) {
        final parentDir = file.parent.path;
        await Process.run('xdg-open', [parentDir]);
      }
    } catch (e) {
      if (!context.mounted) return;
      await showMacosAlertDialog(
        context: context,
        builder: (_) => MacosAlertDialog(
          appIcon: const MacosIcon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 64,
            color: MacosColors.systemOrangeColor,
          ),
          title: Text(
            'Error',
            style: MacosTheme.of(context).typography.headline,
          ),
          message: Text('Failed to reveal artifact: $e', textAlign: TextAlign.center),
          primaryButton: PushButton(
            controlSize: ControlSize.large,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ),
      );
    }
  }
}
