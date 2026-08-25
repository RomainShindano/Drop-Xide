import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/build_provider.dart';
import '../providers/publish_provider.dart';
import '../providers/settings_provider.dart';
import '../models/build_history.dart';
import '../models/publish_history.dart';
import '../widgets/project_list_widget.dart';
import '../widgets/build_config_widget.dart';
import '../widgets/build_history_widget.dart';
import '../widgets/build_queue_widget.dart';
import '../widgets/build_templates_widget.dart';
import '../widgets/google_play_publish_widget.dart';
import '../widgets/publish_history_widget.dart';
import '../widgets/settings_widget.dart';
import '../widgets/ui/macos_polish.dart';
import 'add_project_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pageIndex = 0;

  void _goTo(int index) => setState(() => _pageIndex = index);

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    final selected = context.watch<ProjectProvider>().selectedProject;
    final isBuilding = context.watch<BuildProvider>().isBuilding;
    final isPublishing = context.watch<PublishProvider>().currentPublish?.status == 
        PublishStatus.uploading || 
        context.watch<PublishProvider>().currentPublish?.status == PublishStatus.processing;

    return MacosWindow(
      sidebar: Sidebar(
        minWidth: 200,
        startWidth: 228,
        topOffset: 52,
        top: Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      MacosTheme.of(context).primaryColor,
                      MacosTheme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Center(
                  child: MacosIcon(
                    CupertinoIcons.hammer_fill,
                    size: 13,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'DropXide',
                  style: typography.headline.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        builder: (context, scrollController) {
          return SidebarItems(
            currentIndex: _pageIndex,
            onChanged: _goTo,
            scrollController: scrollController,
            itemSize: SidebarItemSize.medium,
            items: [
              const SidebarItem(
                leading: MacosIcon(CupertinoIcons.folder),
                label: Text('Projects'),
              ),
              SidebarItem(
                leading: const MacosIcon(CupertinoIcons.hammer),
                label: const Text('Build'),
                trailing: isBuilding
                    ? const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: ProgressCircle(radius: 6),
                      )
                    : null,
              ),
              const SidebarItem(
                leading: MacosIcon(CupertinoIcons.doc_text),
                label: Text('Logs'),
              ),
              SidebarItem(
                leading: const MacosIcon(CupertinoIcons.cloud_upload),
                label: const Text('Publish'),
                trailing: isPublishing
                    ? const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: ProgressCircle(radius: 6),
                      )
                    : null,
              ),
              const SidebarItem(
                leading: MacosIcon(CupertinoIcons.time),
                label: Text('Publish History'),
              ),
              const SidebarItem(
                leading: MacosIcon(CupertinoIcons.settings),
                label: Text('Settings'),
              ),
            ],
          );
        },
        bottom: selected == null
            ? null
            : Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: HoverSurface(
                  selected: _pageIndex == 1,
                  onTap: () => _goTo(1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      MacosIcon(
                        CupertinoIcons.folder_fill,
                        size: 14,
                        color: MacosTheme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected',
                              style: typography.caption2.copyWith(
                                color: MacosColors.secondaryLabelColor
                                    .resolveFrom(context),
                              ),
                            ),
                            Text(
                              selected.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: typography.caption1.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const MacosIcon(
                        CupertinoIcons.chevron_right,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
      ),
      child: IndexedStack(
        index: _pageIndex,
        children: [
          _ProjectsPage(
            onAddProject: _navigateToAddProject,
            onRefresh: _refreshData,
            onOpenBuild: () => _goTo(1),
          ),
          _BuildPage(onRefresh: _refreshData),
          _HistoryPage(onRefresh: _refreshData),
          _PublishPage(onRefresh: _refreshData),
          _PublishHistoryPage(onRefresh: _refreshData),
          const _SettingsPage(),
        ],
      ),
    );
  }

  Future<void> _navigateToAddProject() async {
    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(builder: (_) => const AddProjectScreen()),
    );

    if (result == true && mounted) {
      context.read<ProjectProvider>().loadProjects();
      _goTo(0);
    }
  }

  void _refreshData() {
    context.read<ProjectProvider>().loadProjects();
    context.read<BuildProvider>().loadBuildHistory();
    context.read<PublishProvider>().loadPublishHistory();
  }
}

class _ProjectsPage extends StatelessWidget {
  final VoidCallback onAddProject;
  final VoidCallback onRefresh;
  final VoidCallback onOpenBuild;

  const _ProjectsPage({
    required this.onAddProject,
    required this.onRefresh,
    required this.onOpenBuild,
  });

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Projects'),
        titleWidth: 120,
        actions: [
          ToolBarIconButton(
            label: 'Add Project',
            icon: const MacosIcon(CupertinoIcons.add),
            onPressed: onAddProject,
            showLabel: false,
            tooltipMessage: 'Add Project',
          ),
          ToolBarIconButton(
            label: 'Refresh',
            icon: const MacosIcon(CupertinoIcons.refresh),
            onPressed: onRefresh,
            showLabel: false,
            tooltipMessage: 'Refresh',
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return ProjectListWidget(
              onAddProject: onAddProject,
              onOpenBuild: onOpenBuild,
            );
          },
        ),
      ],
    );
  }
}

class _BuildPage extends StatelessWidget {
  final VoidCallback onRefresh;

  const _BuildPage({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isBuilding = context.watch<BuildProvider>().isBuilding;
    final status = context.watch<BuildProvider>().currentBuild?.status;

    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Build'),
        titleWidth: 100,
        actions: [
          if (isBuilding || status == BuildStatus.running)
            CustomToolbarItem(
              inToolbarBuilder: (context) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: StatusPill(
                  label: 'Building',
                  color: MacosColors.systemBlueColor,
                ),
              ),
            ),
          ToolBarIconButton(
            label: 'Refresh',
            icon: const MacosIcon(CupertinoIcons.refresh),
            onPressed: onRefresh,
            showLabel: false,
            tooltipMessage: 'Refresh',
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return const BuildConfigWidget();
          },
        ),
      ],
    );
  }
}

class _HistoryPage extends StatelessWidget {
  final VoidCallback onRefresh;

  const _HistoryPage({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Logs'),
        titleWidth: 80,
        actions: [
          ToolBarIconButton(
            label: 'Refresh',
            icon: const MacosIcon(CupertinoIcons.refresh),
            onPressed: onRefresh,
            showLabel: false,
            tooltipMessage: 'Refresh',
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return const BuildHistoryWidget();
          },
        ),
      ],
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Settings'),
        titleWidth: 100,
        actions: [
          ToolBarIconButton(
            label: 'Refresh',
            icon: const MacosIcon(CupertinoIcons.refresh),
            onPressed: () => context.read<SettingsProvider>().load(),
            showLabel: false,
            tooltipMessage: 'Refresh',
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return const SettingsWidget();
          },
        ),
      ],
    );
  }
}

class _PublishPage extends StatelessWidget {
  final VoidCallback onRefresh;

  const _PublishPage({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isPublishing = context.watch<PublishProvider>().currentPublish?.status == 
        PublishStatus.uploading || 
        context.watch<PublishProvider>().currentPublish?.status == PublishStatus.processing;

    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Publish to Play Store'),
        titleWidth: 180,
        actions: [
          if (isPublishing)
            CustomToolbarItem(
              inToolbarBuilder: (context) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: StatusPill(
                  label: 'Publishing',
                  color: MacosColors.systemBlueColor,
                ),
              ),
            ),
          ToolBarIconButton(
            label: 'Refresh',
            icon: const MacosIcon(CupertinoIcons.refresh),
            onPressed: onRefresh,
            showLabel: false,
            tooltipMessage: 'Refresh',
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return const GooglePlayPublishWidget();
          },
        ),
      ],
    );
  }
}

class _PublishHistoryPage extends StatelessWidget {
  final VoidCallback onRefresh;

  const _PublishHistoryPage({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Publish History'),
        titleWidth: 140,
        actions: [
          ToolBarIconButton(
            label: 'Refresh',
            icon: const MacosIcon(CupertinoIcons.refresh),
            onPressed: onRefresh,
            showLabel: false,
            tooltipMessage: 'Refresh',
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return const PublishHistoryWidget();
          },
        ),
      ],
    );
  }
}
