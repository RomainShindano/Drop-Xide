import 'dart:io';

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
  final VoidCallback? onOpenBuild;

  const ProjectDetailsWidget({
    super.key,
    this.onAddProject,
    this.onOpenBuild,
  });

  @override
  State<ProjectDetailsWidget> createState() => _ProjectDetailsWidgetState();
}

class _ProjectDetailsWidgetState extends State<ProjectDetailsWidget> {
  final _gitService = GitService();
  String? _loadedPath;
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
            message:
                'Choose a project from the toolbar, or add a Flutter project to get started.',
            actionLabel: 'Add Project',
            onAction: widget.onAddProject,
          );
        }

        if (_loadedPath != selectedProject.path && !_loadingGitInfo) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadGitInfo(selectedProject.path);
          });
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProjectHero(
                    project: selectedProject,
                    branch: _currentBranch,
                    isGitRepo: _isGitRepo,
                    loadingGit: _loadingGitInfo,
                    onOpenBuild: widget.onOpenBuild,
                    onRevealInFinder: () =>
                        _revealInFinder(selectedProject.path),
                  ),
                  const SizedBox(height: 18),
                  _MetaStrip(
                    project: selectedProject,
                    branchCount: _branches.length,
                    isGitRepo: _isGitRepo,
                  ),
                  if (_isGitRepo) ...[
                    const SizedBox(height: 28),
                    _GitSection(
                      currentBranch: _currentBranch,
                      branches: _branches,
                      commits: _commits,
                      loading: _loadingGitInfo,
                      onRefresh: () => _loadGitInfo(selectedProject.path),
                    ),
                  ],
                  if (selectedProject.lastBuildConfig != null) ...[
                    const SizedBox(height: 28),
                    _LastBuildSection(config: selectedProject.lastBuildConfig!),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadGitInfo(String projectPath) async {
    setState(() {
      _loadingGitInfo = true;
      _loadedPath = projectPath;
    });
    try {
      final isGit = await _gitService.isGitRepository(projectPath);
      if (!mounted || _loadedPath != projectPath) return;

      if (!isGit) {
        setState(() {
          _isGitRepo = false;
          _currentBranch = null;
          _branches = [];
          _commits = [];
        });
        return;
      }

      final branch = await _gitService.getCurrentBranch(projectPath);
      final branches = await _gitService.getAllBranches(projectPath);
      final commits =
          await _gitService.getRecentCommits(projectPath, limit: 8);

      if (!mounted || _loadedPath != projectPath) return;

      setState(() {
        _isGitRepo = true;
        _currentBranch = branch;
        _branches = branches;
        _commits = commits;
      });
    } catch (_) {
      if (!mounted || _loadedPath != projectPath) return;
      setState(() {
        _isGitRepo = false;
        _currentBranch = null;
        _branches = [];
        _commits = [];
      });
    } finally {
      if (mounted && _loadedPath == projectPath) {
        setState(() => _loadingGitInfo = false);
      }
    }
  }

  Future<void> _revealInFinder(String path) async {
    await Process.run('open', [path]);
  }
}

class _ProjectHero extends StatelessWidget {
  final FlutterProject project;
  final String? branch;
  final bool isGitRepo;
  final bool loadingGit;
  final VoidCallback? onOpenBuild;
  final VoidCallback onRevealInFinder;

  const _ProjectHero({
    required this.project,
    required this.branch,
    required this.isGitRepo,
    required this.loadingGit,
    required this.onOpenBuild,
    required this.onRevealInFinder,
  });

  @override
  Widget build(BuildContext context) {
    final primary = MacosTheme.of(context).primaryColor;
    final isDark = MacosTheme.brightnessOf(context) == Brightness.dark;

    return SectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary,
                      primary.withValues(alpha: 0.72),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: isDark ? 0.35 : 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: MacosIcon(
                    CupertinoIcons.folder_fill,
                    size: 26,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name, style: context.dxHeadline),
                    const SizedBox(height: 6),
                    Text(
                      project.path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.dxCaption.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (loadingGit)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: ProgressCircle(radius: 8),
                          )
                        else if (isGitRepo)
                          StatusPill(
                            label: branch ?? 'detached',
                            color: primary,
                          )
                        else
                          StatusPill(
                            label: 'Not a Git repo',
                            color: MacosColors.systemGrayColor,
                          ),
                        if (project.description != null &&
                            project.description!.trim().isNotEmpty)
                          StatusPill(
                            label: 'Has notes',
                            color: MacosColors.systemOrangeColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (project.description != null &&
              project.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              project.description!,
              style: context.dxBody.copyWith(
                color: context.dxSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              if (onOpenBuild != null)
                SleekButton.label(
                  label: 'Build',
                  leadingIcon: CupertinoIcons.hammer_fill,
                  onPressed: onOpenBuild,
                ),
              if (onOpenBuild != null) const SizedBox(width: 10),
              SleekButton.label(
                label: 'Reveal in Finder',
                leadingIcon: CupertinoIcons.folder,
                secondary: true,
                onPressed: onRevealInFinder,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaStrip extends StatelessWidget {
  final FlutterProject project;
  final int branchCount;
  final bool isGitRepo;

  const _MetaStrip({
    required this.project,
    required this.branchCount,
    required this.isGitRepo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetaTile(
            icon: CupertinoIcons.calendar,
            label: 'Added',
            value: DateFormat('MMM d, y').format(project.addedAt),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetaTile(
            icon: CupertinoIcons.hammer,
            label: 'Last build',
            value: project.lastBuildAt == null
                ? 'Never'
                : DateFormat('MMM d, y').format(project.lastBuildAt!),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetaTile(
            icon: CupertinoIcons.arrow_branch,
            label: 'Branches',
            value: isGitRepo ? '$branchCount' : '—',
          ),
        ),
      ],
    );
  }
}

class _MetaTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final primary = MacosTheme.of(context).primaryColor;

    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: MacosIcon(icon, size: 15, color: primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.dxCaption),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.dxCallout.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GitSection extends StatelessWidget {
  final String? currentBranch;
  final List<String> branches;
  final List<GitCommit> commits;
  final bool loading;
  final VoidCallback onRefresh;

  const _GitSection({
    required this.currentBranch,
    required this.branches,
    required this.commits,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final primary = MacosTheme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Git',
          subtitle: currentBranch == null
              ? 'Repository overview'
              : 'On $currentBranch',
          trailing: SleekButton.label(
            label: 'Refresh',
            size: SleekButtonSize.small,
            secondary: true,
            leadingIcon: CupertinoIcons.refresh,
            onPressed: loading ? null : onRefresh,
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Branches', style: context.dxSectionLabel),
              const SizedBox(height: 10),
              if (branches.isEmpty)
                Text('No branches found', style: context.dxCaption)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final branch in branches.take(12))
                      _BranchChip(
                        name: branch,
                        selected: branch == currentBranch,
                        color: primary,
                      ),
                    if (branches.length > 12)
                      Text(
                        '+${branches.length - 12} more',
                        style: context.dxCaption,
                      ),
                  ],
                ),
              if (commits.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  height: 1,
                  color: MacosColors.separatorColor.withValues(alpha: 0.45),
                ),
                const SizedBox(height: 16),
                Text('Recent commits', style: context.dxSectionLabel),
                const SizedBox(height: 12),
                for (var i = 0; i < commits.length; i++) ...[
                  _CommitRow(commit: commits[i], isLast: i == commits.length - 1),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BranchChip extends StatelessWidget {
  final String name;
  final bool selected;
  final Color color;

  const _BranchChip({
    required this.name,
    required this.selected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? color.withValues(alpha: 0.16)
            : MacosColors.controlBackgroundColor.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected
              ? color.withValues(alpha: 0.35)
              : MacosColors.separatorColor.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MacosIcon(
            CupertinoIcons.arrow_branch,
            size: 11,
            color: selected ? color : context.dxSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: context.dxCaption.copyWith(
              color: selected ? color : context.dxLabel,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommitRow extends StatelessWidget {
  final GitCommit commit;
  final bool isLast;

  const _CommitRow({required this.commit, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final primary = MacosTheme.of(context).primaryColor;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 1.5,
                  height: 36,
                  margin: const EdgeInsets.only(top: 4),
                  color: MacosColors.separatorColor.withValues(alpha: 0.5),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commit.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.dxCallout.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${commit.hash.substring(0, 7)}  ·  ${commit.author}  ·  ${_formatDate(commit.date)}',
                  style: context.dxCaption.copyWith(fontFamily: 'Menlo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays == 0) {
      if (difference.inHours == 0) return '${difference.inMinutes}m ago';
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) return 'yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }
}

class _LastBuildSection extends StatelessWidget {
  final BuildConfig config;

  const _LastBuildSection({required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Last build',
          subtitle: 'Most recent configuration used for this project',
        ),
        SectionCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ConfigChip(
                icon: CupertinoIcons.device_phone_portrait,
                label: config.platform.name.toUpperCase(),
              ),
              _ConfigChip(
                icon: CupertinoIcons.speedometer,
                label: config.mode.name.toUpperCase(),
              ),
              if (config.buildType != null)
                _ConfigChip(
                  icon: CupertinoIcons.cube_box,
                  label: config.buildType!.name.toUpperCase(),
                ),
              if (config.flavor != null)
                _ConfigChip(
                  icon: CupertinoIcons.tag,
                  label: config.flavor!,
                ),
              if (config.branch != null)
                _ConfigChip(
                  icon: CupertinoIcons.arrow_branch,
                  label: config.branch!,
                ),
              if (config.obfuscate)
                const _ConfigChip(
                  icon: CupertinoIcons.lock_fill,
                  label: 'Obfuscated',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfigChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ConfigChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: MacosColors.systemGrayColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.dxSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.dxCaption.copyWith(
              color: context.dxLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
