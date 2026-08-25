import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/flutter_project.dart';
import '../services/git_service.dart';
import 'ui/macos_polish.dart';
import 'ui/sleek_button.dart';

class ProjectDetailsWidget extends StatefulWidget {
  final VoidCallback? onAddProject;

  const ProjectDetailsWidget({
    super.key,
    this.onAddProject,
  });

  @override
  State<ProjectDetailsWidget> createState() => _ProjectDetailsWidgetState();
}

class _ProjectDetailsWidgetState extends State<ProjectDetailsWidget> {
  final _gitService = GitService();
  bool _isGitRepo = false;
  String? _currentBranch;
  List<String> _branches = [];
  List<GitCommit> _commits = [];
  bool _loadingGitInfo = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final selectedProject = provider.selectedProject;

        if (selectedProject == null) {
          return EmptyState(
            icon: CupertinoIcons.folder_badge_plus,
            title: 'No project selected',
            message: 'Select a project from the dropdown above or add a new Flutter project.',
            actionLabel: 'Add Project',
            onAction: widget.onAddProject,
          );
        }

        // Load Git info when project changes
        if (!_loadingGitInfo) {
          _loadGitInfo(selectedProject.path);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProjectInfoSection(project: selectedProject),
                  if (_isGitRepo) ...[
                    const SizedBox(height: 20),
                    _GitInfoSection(
                      currentBranch: _currentBranch,
                      branches: _branches,
                      commits: _commits,
                      onRefresh: () => _loadGitInfo(selectedProject.path),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _BuildInfoSection(project: selectedProject),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadGitInfo(String projectPath) async {
    setState(() => _loadingGitInfo = true);
    try {
      final isGit = await _gitService.isGitRepository(projectPath);
      if (!mounted) return;
      
      setState(() => _isGitRepo = isGit);

      if (isGit) {
        final branch = await _gitService.getCurrentBranch(projectPath);
        final branches = await _gitService.getAllBranches(projectPath);
        final commits = await _gitService.getRecentCommits(projectPath, limit: 10);
        
        if (!mounted) return;
        
        setState(() {
          _currentBranch = branch;
          _branches = branches;
          _commits = commits;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGitRepo = false);
    } finally {
      if (mounted) {
        setState(() => _loadingGitInfo = false);
      }
    }
  }
}

class _ProjectInfoSection extends StatelessWidget {
  final FlutterProject project;

  const _ProjectInfoSection({required this.project});

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Project Information',
          subtitle: 'Overview and metadata',
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          MacosTheme.of(context).primaryColor,
                          MacosTheme.of(context).primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: MacosIcon(
                        CupertinoIcons.folder_fill,
                        size: 22,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: typography.title1.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.path,
                          style: typography.body.copyWith(
                            color: MacosColors.secondaryLabelColor.resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _InfoRow(
                label: 'Added',
                value: _formatDate(project.addedAt),
                icon: CupertinoIcons.calendar,
              ),
              if (project.lastBuildAt != null) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Last Built',
                  value: _formatDate(project.lastBuildAt!),
                  icon: CupertinoIcons.hammer,
                ),
              ],
              if (project.description != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: typography.headline.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  project.description!,
                  style: typography.body.copyWith(
                    color: MacosColors.secondaryLabelColor.resolveFrom(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y \'at\' h:mm a').format(date);
  }
}

class _GitInfoSection extends StatelessWidget {
  final String? currentBranch;
  final List<String> branches;
  final List<GitCommit> commits;
  final VoidCallback onRefresh;

  const _GitInfoSection({
    required this.currentBranch,
    required this.branches,
    required this.commits,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Git Information',
          subtitle: 'Branches and recent commits',
          trailing: SleekButton.label(
            label: 'Refresh',
            size: SleekButtonSize.small,
            secondary: true,
            leadingIcon: CupertinoIcons.refresh,
            onPressed: onRefresh,
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: 'Current Branch',
                value: currentBranch ?? 'Unknown',
                icon: CupertinoIcons.branch,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Total Branches',
                value: branches.length.toString(),
                icon: CupertinoIcons.list_bullet,
              ),
              if (branches.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Branches',
                  style: typography.headline.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: branches.take(10).map((branch) {
                    final isCurrent = branch == currentBranch;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? MacosTheme.of(context).primaryColor.withValues(alpha: 0.15)
                            : MacosColors.controlBackgroundColor.resolveFrom(context),
                        borderRadius: BorderRadius.circular(6),
                        border: isCurrent
                            ? Border.all(
                                color: MacosTheme.of(context).primaryColor.withValues(alpha: 0.3),
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MacosIcon(
                            CupertinoIcons.branch,
                            size: 12,
                            color: isCurrent
                                ? MacosTheme.of(context).primaryColor
                                : MacosColors.secondaryLabelColor.resolveFrom(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            branch,
                            style: typography.caption1.copyWith(
                              color: isCurrent
                                  ? MacosTheme.of(context).primaryColor
                                  : MacosColors.labelColor.resolveFrom(context),
                              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (branches.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+ ${branches.length - 10} more',
                      style: typography.caption2.copyWith(
                        color: MacosColors.secondaryLabelColor.resolveFrom(context),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (commits.isNotEmpty) ...[
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Commits',
                  style: typography.headline.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ...commits.map((commit) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _CommitRow(commit: commit),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BuildInfoSection extends StatelessWidget {
  final FlutterProject project;

  const _BuildInfoSection({required this.project});

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;

    if (project.lastBuildConfig == null) {
      return const SizedBox.shrink();
    }

    final config = project.lastBuildConfig!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Last Build Configuration',
          subtitle: 'Most recent build settings',
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: 'Platform',
                value: config.platform.name.toUpperCase(),
                icon: CupertinoIcons.device_phone_portrait,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Mode',
                value: config.mode.name.toUpperCase(),
                icon: CupertinoIcons.speedometer,
              ),
              if (config.buildType != null) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Build Type',
                  value: config.buildType!.name.toUpperCase(),
                  icon: CupertinoIcons.cube_box,
                ),
              ],
              if (config.flavor != null) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Flavor',
                  value: config.flavor!,
                  icon: CupertinoIcons.tag,
                ),
              ],
              if (config.branch != null) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Branch',
                  value: config.branch!,
                  icon: CupertinoIcons.branch,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: MacosTheme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: MacosIcon(
              icon,
              size: 14,
              color: MacosTheme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: typography.caption1.copyWith(
                  color: MacosColors.secondaryLabelColor.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: typography.headline.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommitRow extends StatelessWidget {
  final GitCommit commit;

  const _CommitRow({required this.commit});

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    final secondary = MacosColors.secondaryLabelColor.resolveFrom(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: MacosTheme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                commit.message,
                style: typography.body.copyWith(fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    commit.hash.substring(0, 7),
                    style: typography.caption2.copyWith(
                      color: secondary,
                      fontFamily: 'Menlo',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: typography.caption2.copyWith(color: secondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    commit.author,
                    style: typography.caption2.copyWith(color: secondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: typography.caption2.copyWith(color: secondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(commit.date),
                    style: typography.caption2.copyWith(color: secondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) return 'yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }
}

class GitCommit {
  final String hash;
  final String message;
  final String author;
  final DateTime date;

  GitCommit({
    required this.hash,
    required this.message,
    required this.author,
    required this.date,
  });
}
