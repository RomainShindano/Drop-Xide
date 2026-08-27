import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_file_picker.dart';
import 'ui/macos_polish.dart';
import 'ui/sleek_button.dart';

class SettingsWidget extends StatelessWidget {
  const SettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        if (settings.isLoading && settings.accounts.isEmpty) {
          return const Center(child: ProgressCircle());
        }

        final typography = MacosTheme.of(context).typography;
        final secondary = MacosColors.secondaryLabelColor.resolveFrom(context);
        final flutterOk = settings.isFlutterAvailable;

        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      title: 'Flutter SDK',
                      subtitle: 'Required to run builds from Drop-Xide',
                    ),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: (flutterOk
                                          ? MacosColors.systemGreenColor
                                          : MacosColors.systemRedColor)
                                      .withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: MacosIcon(
                                    flutterOk
                                        ? CupertinoIcons.checkmark_seal_fill
                                        : CupertinoIcons.xmark_seal_fill,
                                    color: flutterOk
                                        ? MacosColors.systemGreenColor
                                        : MacosColors.systemRedColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      flutterOk
                                          ? 'Flutter detected'
                                          : 'Flutter not found',
                                      style: typography.headline.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: context.dxLabel,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      flutterOk
                                          ? '${settings.flutterInfo['version']}\n${settings.flutterInfo['path']}'
                                          : 'Choose your Flutter SDK folder, or install Flutter below.',
                                      style: typography.caption1.copyWith(
                                        color: secondary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SleekButton.label(
                                label: flutterOk ? 'Change…' : 'Locate…',
                                size: SleekButtonSize.small,
                                leadingIcon: CupertinoIcons.folder,
                                onPressed: () => _locateSdk(context),
                              ),
                              const SizedBox(width: 8),
                              SleekButton.label(
                                label: 'Refresh',
                                size: SleekButtonSize.small,
                                secondary: true,
                                leadingIcon: CupertinoIcons.refresh,
                                onPressed: settings.refreshSdk,
                              ),
                            ],
                          ),
                          if (settings.flutterInfo['isManual'] == true) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Using a folder you selected manually.',
                                    style: typography.caption1
                                        .copyWith(color: secondary),
                                  ),
                                ),
                                SleekButton.label(
                                  label: 'Use Auto-Detect',
                                  size: SleekButtonSize.small,
                                  secondary: true,
                                  onPressed: settings.clearFlutterSdkPath,
                                ),
                              ],
                            ),
                          ],
                          if (!flutterOk) ...[
                            const SizedBox(height: 14),
                            Text(
                              'Install Flutter',
                              style: typography.subheadline.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.dxLabel,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Homebrew:\n'
                              '    brew install --cask flutter\n\n'
                              'Or download the SDK from docs.flutter.dev/get-started/install/macos '
                              'and unzip it, then press Locate… and choose the "flutter" folder.\n\n'
                              'Already installed? Drop-Xide is launched from Finder, which does not '
                              'read your shell PATH, so use Locate… to point at the SDK folder '
                              '(the one containing bin/flutter).',
                              style: typography.caption1.copyWith(
                                color: secondary,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SectionHeader(
                      title: 'Google Play',
                      subtitle:
                          'Service accounts used for Play Console publishing',
                      trailing: SleekButton.label(
                        label: 'Add Account',
                        size: SleekButtonSize.small,
                        leadingIcon: CupertinoIcons.plus,
                        onPressed: () => _addAccount(context),
                      ),
                    ),
                    if (settings.accounts.isEmpty)
                      SectionCard(
                        child: Row(
                          children: [
                            MacosIcon(
                              CupertinoIcons.person_crop_circle_badge_plus,
                              color: secondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No service accounts yet. Add a Play Console JSON key when you’re ready to publish.',
                                style: typography.body.copyWith(
                                  color: secondary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...settings.accounts.map((account) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SectionCard(
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: MacosTheme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Center(
                                    child: MacosIcon(
                                      CupertinoIcons.person_crop_circle,
                                      color:
                                          MacosTheme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        account.name,
                                        style: typography.headline.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        account.email,
                                        style: typography.caption1
                                            .copyWith(color: secondary),
                                      ),
                                      Text(
                                        'Project: ${account.projectId}',
                                        style: typography.caption2
                                            .copyWith(color: secondary),
                                      ),
                                    ],
                                  ),
                                ),
                                MacosIconButton(
                                  icon: MacosIcon(
                                    CupertinoIcons.trash,
                                    color: MacosColors.systemRedColor
                                        .withValues(alpha: 0.85),
                                    size: 15,
                                  ),
                                  onPressed: () =>
                                      _deleteAccount(context, account.id),
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
                      }),
                    if (settings.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        settings.error!,
                        style: typography.caption1.copyWith(
                          color: MacosColors.systemRedColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    const SectionHeader(
                      title: 'About',
                      subtitle: 'Drop-Xide build automation',
                    ),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Drop-Xide',
                            style: typography.headline.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A native macOS companion for Flutter project builds, history, and Play Console accounts.',
                            style: typography.body.copyWith(
                              color: secondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _locateSdk(BuildContext context) async {
    final path = await AppFilePicker.pickDirectory(
      dialogTitle: 'Choose your Flutter SDK folder (the one containing bin/flutter)',
      confirmButtonText: 'Use SDK',
    );
    if (path == null || !context.mounted) return;

    final ok = await context.read<SettingsProvider>().setFlutterSdkPath(path);
    if (ok || !context.mounted) return;

    await showMacosAlertDialog(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: const MacosIcon(
          CupertinoIcons.exclamationmark_triangle_fill,
          size: 64,
          color: MacosColors.systemOrangeColor,
        ),
        title: Text(
          'Not a Flutter SDK',
          style: MacosTheme.of(context).typography.headline,
        ),
        message: Text(
          'No Flutter SDK was found at:\n$path\n\n'
          'Choose the folder that contains bin/flutter — usually named '
          '"flutter".',
          textAlign: TextAlign.center,
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ),
    );
  }

  Future<void> _addAccount(BuildContext context) async {
    final nameController = TextEditingController(text: 'Play Console');

    final confirmed = await showMacosAlertDialog<bool>(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: const MacosIcon(
          CupertinoIcons.doc_on_clipboard,
          size: 64,
          color: MacosColors.systemBlueColor,
        ),
        title: Text(
          'Add Service Account',
          style: MacosTheme.of(context).typography.headline,
        ),
        message: Column(
          children: [
            const Text(
              'Choose a display name, then pick the service account JSON file.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            MacosTextField(
              controller: nameController,
              placeholder: 'Account name',
            ),
          ],
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Choose File…'),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final path = await AppFilePicker.pickJsonFile(
      confirmButtonText: 'Add Account',
    );
    if (path == null || !context.mounted) return;

    try {
      await context.read<SettingsProvider>().addServiceAccount(
            nameController.text.trim().isEmpty
                ? 'Play Console'
                : nameController.text.trim(),
            path,
          );
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
            'Could Not Add Account',
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
    } finally {
      nameController.dispose();
    }
  }

  Future<void> _deleteAccount(BuildContext context, String id) async {
    final confirm = await showMacosAlertDialog<bool>(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: const MacosIcon(
          CupertinoIcons.trash,
          size: 64,
          color: MacosColors.systemRedColor,
        ),
        title: Text(
          'Remove Account',
          style: MacosTheme.of(context).typography.headline,
        ),
        message: const Text(
          'Remove this Google Play service account from Drop-Xide?',
          textAlign: TextAlign.center,
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          color: MacosColors.systemRedColor,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remove'),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<SettingsProvider>().deleteServiceAccount(id);
    }
  }
}
