import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/build_provider.dart';
import '../models/build_template.dart';
import '../models/flutter_project.dart';
import '../utils/error_handler.dart';
import 'ui/macos_polish.dart';
import 'ui/sleek_button.dart';

class BuildTemplatesWidget extends StatelessWidget {
  final FlutterProject? selectedProject;
  final void Function(BuildConfig config)? onTemplateSelected;

  const BuildTemplatesWidget({
    super.key,
    this.selectedProject,
    this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BuildProvider>(
      builder: (context, provider, child) {
        final templates = provider.templates;
        final favorites = templates.where((t) => t.isFavorite).toList();
        final others = templates.where((t) => !t.isFavorite).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
          children: [
            if (favorites.isNotEmpty) ...[
              const SectionHeader(
                title: 'Favorite Templates',
                subtitle: 'Frequently used build configurations',
              ),
              ...favorites.map((template) => _TemplateCard(
                    template: template,
                    onUse: () => _useTemplate(context, template),
                    onDelete: () => _deleteTemplate(context, provider, template),
                    onToggleFavorite: () =>
                        provider.toggleTemplateFavorite(template.id),
                  )),
              const SizedBox(height: 24),
            ],
            if (others.isNotEmpty) ...[
              const SectionHeader(
                title: 'All Templates',
                subtitle: 'Saved build configurations',
              ),
              ...others.map((template) => _TemplateCard(
                    template: template,
                    onUse: () => _useTemplate(context, template),
                    onDelete: () => _deleteTemplate(context, provider, template),
                    onToggleFavorite: () =>
                        provider.toggleTemplateFavorite(template.id),
                  )),
            ],
            if (templates.isEmpty) ...[
              const SizedBox(height: 100),
              Center(
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.doc_on_doc,
                      size: 64,
                      color: MacosColors.systemGrayColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text('No Templates Yet', style: context.dxTitle),
                    const SizedBox(height: 8),
                    Text(
                      'Save build configurations as templates for quick access',
                      textAlign: TextAlign.center,
                      style: context.dxCaption,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _useTemplate(BuildContext context, BuildTemplate template) async {
    final provider = context.read<BuildProvider>();
    await provider.useTemplate(template.id);
    
    if (onTemplateSelected != null) {
      onTemplateSelected!(template.buildConfig);
    }

    if (context.mounted) {
      ErrorHandler.showSuccessSnackBar(
        context,
        'Template "${template.name}" loaded',
      );
    }
  }

  Future<void> _deleteTemplate(
    BuildContext context,
    BuildProvider provider,
    BuildTemplate template,
  ) async {
    final confirm = await showMacosAlertDialog(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: const Icon(CupertinoIcons.trash, size: 48),
        title: const Text('Delete Template'),
        message: Text('Are you sure you want to delete "${template.name}"?'),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
      ),
    );

    if (confirm == true) {
      await provider.deleteTemplate(template.id);
    }
  }
}

class _TemplateCard extends StatelessWidget {
  final BuildTemplate template;
  final VoidCallback onUse;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const _TemplateCard({
    required this.template,
    required this.onUse,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  CupertinoIcons.doc_fill,
                  color: MacosColors.systemBlueColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(template.name, style: context.dxTitle),
                          if (template.isFavorite) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              CupertinoIcons.star_fill,
                              color: MacosColors.systemYellowColor,
                              size: 14,
                            ),
                          ],
                        ],
                      ),
                      if (template.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          template.description!,
                          style: context.dxCaption,
                        ),
                      ],
                    ],
                  ),
                ),
                MacosIconButton(
                  icon: Icon(
                    template.isFavorite
                        ? CupertinoIcons.star_fill
                        : CupertinoIcons.star,
                    size: 16,
                    color: template.isFavorite
                        ? MacosColors.systemYellowColor
                        : null,
                  ),
                  onPressed: onToggleFavorite,
                ),
                MacosIconButton(
                  icon: const Icon(CupertinoIcons.trash, size: 16),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: CupertinoIcons.device_phone_portrait,
                  label: template.buildConfig.platform.name.toUpperCase(),
                ),
                _InfoChip(
                  icon: CupertinoIcons.gear,
                  label: template.buildConfig.mode.name.toUpperCase(),
                ),
                if (template.buildConfig.flavor != null)
                  _InfoChip(
                    icon: CupertinoIcons.tag,
                    label: template.buildConfig.flavor!,
                  ),
                _InfoChip(
                  icon: CupertinoIcons.chart_bar,
                  label: 'Used ${template.usageCount} times',
                ),
                if (template.lastUsedAt != null)
                  _InfoChip(
                    icon: CupertinoIcons.time,
                    label: 'Last used ${_formatDate(template.lastUsedAt!)}',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SleekButton.label(
              label: 'Use Template',
              leadingIcon: CupertinoIcons.play_fill,
              onPressed: onUse,
              expanded: true,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MacosColors.systemGrayColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: MacosColors.secondaryLabelColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.dxCaption,
          ),
        ],
      ),
    );
  }
}
