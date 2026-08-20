import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/flutter_project.dart';
import 'ui/macos_polish.dart';
import 'ui/sleek_button.dart';

class ProjectListWidget extends StatelessWidget {
  final VoidCallback? onAddProject;
  final VoidCallback? onOpenBuild;

  const ProjectListWidget({
    super.key,
    this.onAddProject,
    this.onOpenBuild,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: ProgressCircle());
        }

        if (provider.error != null) {
          return EmptyState(
            icon: CupertinoIcons.exclamationmark_circle,
            title: 'Couldn’t load projects',
            message: provider.error!,
            actionLabel: 'Retry',
            onAction: provider.loadProjects,
          );
        }

        if (provider.projects.isEmpty) {
          return EmptyState(
            icon: CupertinoIcons.folder_badge_plus,
            title: 'No projects yet',
            message:
                'Add a Flutter project to start configuring builds and tracking history.',
            actionLabel: 'Add Project',
            onAction: onAddProject,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: SectionHeader(
                title: 'Your projects',
                subtitle:
                    '${provider.projects.length} project${provider.projects.length == 1 ? '' : 's'}',
                trailing: provider.selectedProject != null && onOpenBuild != null
                    ? SleekButton.label(
                        label: 'Open Build',
                        onPressed: onOpenBuild,
                        size: SleekButtonSize.small,
                      )
                    : null,
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: provider.projects.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final project = provider.projects[index];
                  return _ProjectRow(
                    project: project,
                    isSelected: provider.selectedProject?.id == project.id,
                    onTap: () => provider.selectProject(project),
                    onOpen: onOpenBuild == null
                        ? null
                        : () {
                            provider.selectProject(project);
                            onOpenBuild!();
                          },
                    onDelete: () =>
                        _confirmDelete(context, provider, project),
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
    ProjectProvider provider,
    FlutterProject project,
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
          'Remove Project',
          style: MacosTheme.of(context).typography.headline,
        ),
        message: Text(
          'Remove “${project.name}” from the list? The project files will not be deleted.',
          textAlign: TextAlign.center,
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          color: MacosColors.systemRedColor,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remove'),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          secondary: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ),
    );

    if (confirm == true) {
      await provider.deleteProject(project.id);
    }
  }
}

class _ProjectRow extends StatelessWidget {
  final FlutterProject project;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onOpen;
  final VoidCallback onDelete;

  const _ProjectRow({
    required this.project,
    required this.isSelected,
    required this.onTap,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    final secondary = MacosColors.secondaryLabelColor.resolveFrom(context);
    final primary = MacosTheme.of(context).primaryColor;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: HoverSurface(
        selected: isSelected,
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isSelected ? primary : MacosColors.systemGrayColor)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: MacosIcon(
                  CupertinoIcons.folder_fill,
                  size: 16,
                  color: isSelected ? primary : MacosColors.systemGrayColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: typography.headline.copyWith(
                      color: isSelected ? primary : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    project.path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.caption1.copyWith(color: secondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _metaLabel(project),
                    style: typography.caption2.copyWith(color: secondary),
                  ),
                ],
              ),
            ),
            if (onOpen != null) ...[
              SleekButton.label(
                label: 'Build',
                onPressed: onOpen,
                secondary: true,
                size: SleekButtonSize.small,
                leadingIcon: CupertinoIcons.hammer,
              ),
              const SizedBox(width: 6),
            ],
            MacosIconButton(
              icon: MacosIcon(
                CupertinoIcons.trash,
                color: MacosColors.systemRedColor.withValues(alpha: 0.85),
                size: 15,
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
      ),
    );
  }

  String _metaLabel(FlutterProject project) {
    final added = _formatDate(project.addedAt);
    if (project.lastBuildAt != null) {
      return 'Added $added · Built ${_formatDate(project.lastBuildAt!)}';
    }
    return 'Added $added';
  }

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays == 0) return 'today';
    if (difference.inDays == 1) return 'yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return DateFormat('MMM d, y').format(date);
  }
}
