import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import '../providers/publish_provider.dart';
import '../providers/project_provider.dart';
import '../providers/settings_provider.dart';
import '../models/google_service_account.dart';
import '../models/publish_history.dart';
import '../utils/app_file_picker.dart';
import '../utils/error_handler.dart';
import 'ui/macos_polish.dart';
import 'ui/sleek_button.dart';

class GooglePlayPublishWidget extends StatefulWidget {
  const GooglePlayPublishWidget({super.key});

  @override
  State<GooglePlayPublishWidget> createState() =>
      _GooglePlayPublishWidgetState();
}

class _GooglePlayPublishWidgetState extends State<GooglePlayPublishWidget> {
  String? _selectedAabPath;
  String? _selectedServiceAccountId;
  ReleaseTrack _selectedTrack = ReleaseTrack.internal;
  final _packageNameController = TextEditingController();
  final _versionNameController = TextEditingController();
  final _versionCodeController = TextEditingController();
  final _releaseNotesControllers = <String, TextEditingController>{
    'en-US': TextEditingController(),
  };
  double _rolloutPercentage = 100.0;
  bool _useStagedRollout = false;

  @override
  void dispose() {
    _packageNameController.dispose();
    _versionNameController.dispose();
    _versionCodeController.dispose();
    for (var controller in _releaseNotesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<PublishProvider, ProjectProvider, SettingsProvider>(
      builder: (context, publishProvider, projectProvider, settingsProvider,
          _) {
        final selectedProject = projectProvider.selectedProject;
        final accounts = settingsProvider.accounts;

        if (selectedProject == null) {
          return _buildEmptyState(
            context,
            icon: CupertinoIcons.square_stack_3d_up,
            title: 'No Project Selected',
            subtitle: 'Select a project from the Projects tab to publish',
          );
        }

        if (accounts.isEmpty) {
          return _buildEmptyState(
            context,
            icon: CupertinoIcons.exclamationmark_triangle,
            title: 'No Service Account',
            subtitle:
                'Add a Google Service Account in Settings to publish to Play Store',
            action: () {
              // Navigate to settings
            },
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProjectInfo(context, selectedProject.name),
                    const SizedBox(height: 24),
                    _buildServiceAccountSection(accounts),
                    const SizedBox(height: 16),
                    _buildAabSection(),
                    const SizedBox(height: 16),
                    _buildVersionSection(),
                    const SizedBox(height: 16),
                    _buildReleaseTrackSection(),
                    const SizedBox(height: 16),
                    _buildReleaseNotesSection(),
                    const SizedBox(height: 24),
                    _buildPublishButton(
                      publishProvider,
                      projectProvider,
                      selectedProject.id,
                      selectedProject.name,
                    ),
                    if (publishProvider.currentPublish != null) ...[
                      const SizedBox(height: 16),
                      _buildPublishProgress(publishProvider),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? action,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: MacosColors.systemGrayColor),
          const SizedBox(height: 20),
          Text(title, style: context.dxHeadline),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: context.dxCaption,
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            SleekButton.label(
              label: 'Go to Settings',
              onPressed: action,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectInfo(BuildContext context, String projectName) {
    return SectionCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MacosColors.systemBlueColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.folder_fill,
                color: MacosColors.systemBlueColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Publishing', style: context.dxCaption),
                const SizedBox(height: 2),
                Text(projectName, style: context.dxTitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceAccountSection(
      List<GoogleServiceAccount> accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Service Account',
          subtitle: 'Select the account to use for publishing',
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MacosPopupButton<String>(
                value: _selectedServiceAccountId,
                onChanged: (value) {
                  setState(() {
                    _selectedServiceAccountId = value;
                  });
                },
                items: accounts.map((account) {
                  return MacosPopupMenuItem(
                    value: account.id,
                    child: Text(
                      '${account.name} (${account.email})',
                      overflow: TextOverflow.ellipsis,
                      style: context.dxCallout,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAabSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'App Bundle (AAB)',
          subtitle: 'Select the AAB file to upload',
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedAabPath != null) ...[
                Row(
                  children: [
                    const Icon(CupertinoIcons.doc_fill,
                        color: MacosColors.systemGreenColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedAabPath!.split('/').last,
                        style: context.dxCallout,
                      ),
                    ),
                    MacosIconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill,
                          size: 16),
                      onPressed: () {
                        setState(() {
                          _selectedAabPath = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedAabPath!,
                  style: context.dxCaption,
                ),
                const SizedBox(height: 12),
              ],
              SleekButton.label(
                label: _selectedAabPath == null ? 'Select AAB File' : 'Change AAB File',
                leadingIcon: CupertinoIcons.folder,
                secondary: true,
                expanded: true,
                onPressed: _selectAabFile,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVersionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Version Information',
          subtitle: 'Package name and version details',
        ),
        SectionCard(
          child: Column(
            children: [
              MacosTextField(
                controller: _packageNameController,
                placeholder: 'com.example.app',
                prefix: Text('Package Name', style: context.dxFieldPrefix),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MacosTextField(
                      controller: _versionNameController,
                      placeholder: '1.0.0',
                      prefix: Text('Version Name', style: context.dxFieldPrefix),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MacosTextField(
                      controller: _versionCodeController,
                      placeholder: '1',
                      prefix: Text('Version Code', style: context.dxFieldPrefix),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReleaseTrackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Release Track',
          subtitle: 'Choose where to publish the app',
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...ReleaseTrack.values.map((track) {
                final isSelected = _selectedTrack == track;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTrack = track;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? MacosColors.systemBlueColor.withValues(alpha: 0.1)
                            : MacosColors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? MacosColors.systemBlueColor
                              : MacosColors.separatorColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? CupertinoIcons.check_mark_circled_solid
                                : CupertinoIcons.circle,
                            color: isSelected
                                ? MacosColors.systemBlueColor
                                : MacosColors.systemGrayColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTrackLabel(track),
                                  style: context.dxCallout.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  _getTrackDescription(track),
                                  style: context.dxCaption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (_selectedTrack == ReleaseTrack.production) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    MacosCheckbox(
                      value: _useStagedRollout,
                      onChanged: (value) {
                        setState(() {
                          _useStagedRollout = value;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Text('Use staged rollout', style: context.dxCallout),
                  ],
                ),
                if (_useStagedRollout) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MacosSlider(
                          value: _rolloutPercentage,
                          min: 0,
                          max: 100,
                          onChanged: (value) {
                            setState(() {
                              _rolloutPercentage = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '${_rolloutPercentage.toInt()}%',
                          textAlign: TextAlign.right,
                          style: context.dxCallout.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReleaseNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Release Notes',
          subtitle: 'Describe what\'s new in this version',
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MacosTextField(
                controller: _releaseNotesControllers['en-US']!,
                placeholder: 'Enter release notes...',
                maxLines: 6,
              ),
              const SizedBox(height: 8),
              Text(
                'English (US) - Maximum 500 characters',
                style: context.dxCaption,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPublishButton(
    PublishProvider publishProvider,
    ProjectProvider projectProvider,
    String projectId,
    String projectName,
  ) {
    final isPublishing = publishProvider.currentPublish?.status ==
            PublishStatus.uploading ||
        publishProvider.currentPublish?.status == PublishStatus.processing;

    final canPublish = _selectedAabPath != null &&
        _selectedServiceAccountId != null &&
        _packageNameController.text.isNotEmpty &&
        _versionNameController.text.isNotEmpty &&
        _versionCodeController.text.isNotEmpty &&
        !isPublishing;

    return SleekButton.label(
      label: isPublishing ? 'Publishing...' : 'Publish to Play Store',
      leadingIcon: CupertinoIcons.cloud_upload,
      size: SleekButtonSize.large,
      expanded: true,
      onPressed: canPublish ? () => _handlePublish(publishProvider, projectId, projectName) : null,
    );
  }

  Widget _buildPublishProgress(PublishProvider publishProvider) {
    final publish = publishProvider.currentPublish!;
    final statusText = _getStatusText(publish.status);
    final statusColor = _getStatusColor(publish.status);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(publish.status),
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    if (publish.errorMessage != null)
                      Text(
                        publish.errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: MacosColors.systemRedColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (publish.status == PublishStatus.uploading) ...[
            const SizedBox(height: 12),
            ProgressBar(value: publishProvider.uploadProgress * 100),
            const SizedBox(height: 4),
            Text(
              '${(publishProvider.uploadProgress * 100).toInt()}% uploaded',
              style: context.dxCaption,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectAabFile() async {
    final path = await AppFilePicker.pickFile(
      dialogTitle: 'Select AAB File',
      fileExtension: 'aab',
    );

    if (path != null) {
      setState(() {
        _selectedAabPath = path;
      });
    }
  }

  Future<void> _handlePublish(
    PublishProvider publishProvider,
    String projectId,
    String projectName,
  ) async {
    final versionCode = int.tryParse(_versionCodeController.text);
    if (versionCode == null) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Version code must be a number',
      );
      return;
    }

    try {
      await publishProvider.publishToPlayStore(
        projectId: projectId,
        projectName: projectName,
        packageName: _packageNameController.text,
        serviceAccountId: _selectedServiceAccountId!,
        aabPath: _selectedAabPath!,
        versionName: _versionNameController.text,
        versionCode: versionCode,
        track: _selectedTrack,
        releaseNotes: {
          'en-US': _releaseNotesControllers['en-US']!.text,
        },
        rolloutPercentage: _useStagedRollout ? _rolloutPercentage : null,
      );

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Successfully published to Play Store!',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e.toString());
      }
    }
  }

  String _getTrackLabel(ReleaseTrack track) {
    switch (track) {
      case ReleaseTrack.internal:
        return 'Internal Testing';
      case ReleaseTrack.alpha:
        return 'Alpha';
      case ReleaseTrack.beta:
        return 'Beta';
      case ReleaseTrack.production:
        return 'Production';
    }
  }

  String _getTrackDescription(ReleaseTrack track) {
    switch (track) {
      case ReleaseTrack.internal:
        return 'Share with internal testers only';
      case ReleaseTrack.alpha:
        return 'Early access for alpha testers';
      case ReleaseTrack.beta:
        return 'Pre-release testing with beta users';
      case ReleaseTrack.production:
        return 'Release to all users on Google Play';
    }
  }

  String _getStatusText(PublishStatus status) {
    switch (status) {
      case PublishStatus.pending:
        return 'Preparing...';
      case PublishStatus.uploading:
        return 'Uploading to Play Store...';
      case PublishStatus.processing:
        return 'Processing...';
      case PublishStatus.success:
        return 'Published Successfully!';
      case PublishStatus.failed:
        return 'Publish Failed';
      case PublishStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(PublishStatus status) {
    switch (status) {
      case PublishStatus.pending:
      case PublishStatus.uploading:
      case PublishStatus.processing:
        return MacosColors.systemBlueColor;
      case PublishStatus.success:
        return MacosColors.systemGreenColor;
      case PublishStatus.failed:
        return MacosColors.systemRedColor;
      case PublishStatus.cancelled:
        return MacosColors.systemOrangeColor;
    }
  }

  IconData _getStatusIcon(PublishStatus status) {
    switch (status) {
      case PublishStatus.pending:
      case PublishStatus.uploading:
      case PublishStatus.processing:
        return CupertinoIcons.arrow_up_circle_fill;
      case PublishStatus.success:
        return CupertinoIcons.check_mark_circled_solid;
      case PublishStatus.failed:
        return CupertinoIcons.exclamationmark_triangle_fill;
      case PublishStatus.cancelled:
        return CupertinoIcons.xmark_circle_fill;
    }
  }
}
