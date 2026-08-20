import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../utils/app_file_picker.dart';
import '../widgets/ui/macos_polish.dart';
import '../widgets/ui/sleek_button.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  String? _selectedPath;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    final secondary = MacosColors.secondaryLabelColor.resolveFrom(context);

    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Add Project'),
        titleWidth: 140,
        leading: MacosBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: SectionCard(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: MacosTheme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: MacosIcon(
                                CupertinoIcons.folder_badge_plus,
                                size: 30,
                                color: MacosTheme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Select Flutter project',
                          style: typography.title2,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose the folder that contains pubspec.yaml.',
                          style: typography.body.copyWith(
                            color: secondary,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_selectedPath != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: MacosTheme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Selected path', style: typography.headline),
                                const SizedBox(height: 6),
                                Text(
                                  _selectedPath!,
                                  style: typography.caption1.copyWith(
                                    color: secondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        SleekButton.label(
                          label: _selectedPath == null
                              ? 'Browse…'
                              : 'Change Directory…',
                          size: SleekButtonSize.large,
                          secondary: true,
                          expanded: true,
                          leadingIcon: CupertinoIcons.folder,
                          onPressed: _isLoading ? null : _selectDirectory,
                        ),
                        if (_selectedPath != null) ...[
                          const SizedBox(height: 10),
                          SleekButton(
                            size: SleekButtonSize.large,
                            expanded: true,
                            onPressed: _isLoading ? null : _addProject,
                            leadingIcon:
                                _isLoading ? null : CupertinoIcons.plus,
                            child: _isLoading
                                ? const ProgressCircle(radius: 8)
                                : const Text('Add Project'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _selectDirectory() async {
    try {
      final selectedDirectory = await AppFilePicker.pickDirectory(
        confirmButtonText: 'Select Project',
      );
      if (selectedDirectory != null && mounted) {
        setState(() => _selectedPath = selectedDirectory);
      }
    } catch (e) {
      if (!mounted) return;
      await showMacosAlertDialog(
        context: context,
        builder: (_) => MacosAlertDialog(
          appIcon: const MacosIcon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 64,
            color: MacosColors.systemOrangeColor,
          ),
          title: Text(
            'Could Not Open Folder Picker',
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

  Future<void> _addProject() async {
    if (_selectedPath == null) return;

    setState(() => _isLoading = true);

    try {
      await context.read<ProjectProvider>().addProject(_selectedPath!);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        await showMacosAlertDialog(
          context: context,
          builder: (_) => MacosAlertDialog(
            appIcon: const MacosIcon(
              CupertinoIcons.exclamationmark_triangle_fill,
              size: 64,
              color: MacosColors.systemOrangeColor,
            ),
            title: Text(
              'Could Not Add Project',
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
