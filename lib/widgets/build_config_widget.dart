import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/build_provider.dart';
import '../models/flutter_project.dart';
import 'ui/macos_polish.dart';
import 'ui/sleek_button.dart';

class BuildConfigWidget extends StatefulWidget {
  const BuildConfigWidget({super.key});

  @override
  State<BuildConfigWidget> createState() => _BuildConfigWidgetState();
}

class _BuildConfigWidgetState extends State<BuildConfigWidget> {
  BuildPlatform _selectedPlatform = BuildPlatform.android;
  BuildMode _selectedMode = BuildMode.release;
  BuildType _androidBuildType = BuildType.apk;
  String? _flavor;
  bool _obfuscate = false;
  bool _splitDebugInfo = false;
  final _logScrollController = ScrollController();

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  void _scrollLogsToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_logScrollController.hasClients) return;
      _logScrollController.animateTo(
        _logScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProjectProvider, BuildProvider>(
      builder: (context, projectProvider, buildProvider, child) {
        final selectedProject = projectProvider.selectedProject;
        final typography = MacosTheme.of(context).typography;

        if (buildProvider.logs.isNotEmpty) {
          _scrollLogsToEnd();
        }

        if (selectedProject == null) {
          return const EmptyState(
            icon: CupertinoIcons.hammer,
            title: 'No project selected',
            message:
                'Pick a project from the Projects page, then come back here to configure and run a build.',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: MacosTheme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: MacosIcon(
                              CupertinoIcons.folder_fill,
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
                                selectedProject.name,
                                style: typography.headline.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedProject.path,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: typography.caption1.copyWith(
                                  color: MacosColors.secondaryLabelColor
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionHeader(
                    title: 'Configuration',
                    subtitle: 'Choose target platform, mode, and options',
                  ),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Platform', style: typography.headline),
                        const SizedBox(height: 10),
                        MacosPopupButton<BuildPlatform>(
                          value: _selectedPlatform,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedPlatform = value);
                            }
                          },
                          items: BuildPlatform.values
                              .map(
                                (platform) => MacosPopupMenuItem(
                                  value: platform,
                                  child: Text(_platformLabel(platform)),
                                ),
                              )
                              .toList(),
                        ),
                        if (_selectedPlatform == BuildPlatform.android) ...[
                          const SizedBox(height: 16),
                          Text('Android artifact', style: typography.headline),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _RadioLabel(
                                label: 'APK',
                                selected: _androidBuildType == BuildType.apk,
                                onTap: () => setState(
                                  () => _androidBuildType = BuildType.apk,
                                ),
                              ),
                              _RadioLabel(
                                label: 'App Bundle (AAB)',
                                selected:
                                    _androidBuildType == BuildType.appbundle,
                                onTap: () => setState(
                                  () =>
                                      _androidBuildType = BuildType.appbundle,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text('Build mode', style: typography.headline),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: BuildMode.values.map((mode) {
                            return _RadioLabel(
                              label: mode.name,
                              selected: _selectedMode == mode,
                              onTap: () =>
                                  setState(() => _selectedMode = mode),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Advanced', style: typography.headline),
                        const SizedBox(height: 12),
                        MacosTextField(
                          placeholder: 'Flavor (optional)',
                          onChanged: (value) {
                            _flavor = value.isEmpty ? null : value;
                          },
                        ),
                        const SizedBox(height: 14),
                        _SwitchRow(
                          title: 'Obfuscate',
                          subtitle:
                              'Obfuscate Dart code (also enables split debug info)',
                          value: _obfuscate,
                          onChanged: (value) {
                            setState(() {
                              _obfuscate = value;
                              if (value) _splitDebugInfo = true;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        _SwitchRow(
                          title: 'Split debug info',
                          subtitle: 'Store debug symbols separately',
                          value: _splitDebugInfo,
                          onChanged: _obfuscate
                              ? null
                              : (value) {
                                  setState(() => _splitDebugInfo = value);
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SleekButton(
                          size: SleekButtonSize.large,
                          expanded: true,
                          onPressed: buildProvider.isBuilding
                              ? null
                              : () => _startBuild(context),
                          leadingIcon: buildProvider.isBuilding
                              ? null
                              : CupertinoIcons.hammer_fill,
                          child: buildProvider.isBuilding
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ProgressCircle(radius: 8),
                                    SizedBox(width: 8),
                                    Text('Building…'),
                                  ],
                                )
                              : const Text('Start Build'),
                        ),
                      ),
                      if (buildProvider.isBuilding) ...[
                        const SizedBox(width: 12),
                        SleekButton.label(
                          label: 'Cancel',
                          size: SleekButtonSize.large,
                          secondary: true,
                          onPressed: buildProvider.cancelBuild,
                        ),
                      ],
                    ],
                  ),
                  if (buildProvider.logs.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    SectionHeader(
                      title: 'Live logs',
                      subtitle: '${buildProvider.logs.length} lines',
                      trailing: SleekButton.label(
                        label: 'Clear',
                        size: SleekButtonSize.small,
                        secondary: true,
                        onPressed: buildProvider.clearLogs,
                      ),
                    ),
                    SectionCard(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        height: 300,
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          controller: _logScrollController,
                          itemCount: buildProvider.logs.length,
                          itemBuilder: (context, index) {
                            return Text(
                              buildProvider.logs[index],
                              style: const TextStyle(
                                fontFamily: 'Menlo',
                                fontSize: 11.5,
                                height: 1.45,
                                color: Color(0xFF32D74B),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _platformLabel(BuildPlatform platform) {
    switch (platform) {
      case BuildPlatform.android:
        return 'Android';
      case BuildPlatform.ios:
        return 'iOS';
      case BuildPlatform.web:
        return 'Web';
      case BuildPlatform.linux:
        return 'Linux';
      case BuildPlatform.macos:
        return 'macOS';
      case BuildPlatform.windows:
        return 'Windows';
    }
  }

  Future<void> _startBuild(BuildContext context) async {
    final project = context.read<ProjectProvider>().selectedProject!;
    final config = BuildConfig(
      mode: _selectedMode,
      platform: _selectedPlatform,
      buildType: _selectedPlatform == BuildPlatform.android
          ? _androidBuildType
          : null,
      flavor: _flavor,
      obfuscate: _obfuscate,
      splitDebugInfo: _splitDebugInfo || _obfuscate,
    );

    try {
      await context.read<BuildProvider>().startBuild(project, config);
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
            'Could Not Start Build',
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
}

class _RadioLabel extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RadioLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MacosRadioButton<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) => onTap(),
            ),
            const SizedBox(width: 6),
            Text(label, style: MacosTheme.of(context).typography.body),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    final secondary = MacosColors.secondaryLabelColor.resolveFrom(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: typography.body),
              Text(
                subtitle,
                style: typography.caption1.copyWith(color: secondary),
              ),
            ],
          ),
        ),
        MacosSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}
