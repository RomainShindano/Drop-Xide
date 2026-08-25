import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'sleek_button.dart';

/// Theme-aware text helpers for DropXide (fixes black-on-dark text).
extension DropXideTheme on BuildContext {
  MacosTypography get dxTypography => MacosTheme.of(this).typography;

  Color get dxLabel => MacosColors.labelColor.resolveFrom(this);

  Color get dxSecondary => MacosColors.secondaryLabelColor.resolveFrom(this);

  TextStyle get dxTitle => dxTypography.title3.copyWith(
        fontWeight: FontWeight.w600,
        color: dxLabel,
      );

  TextStyle get dxHeadline => dxTypography.title2.copyWith(
        fontWeight: FontWeight.bold,
        color: dxLabel,
      );

  TextStyle get dxBody => dxTypography.body.copyWith(color: dxLabel);

  TextStyle get dxCallout => dxTypography.callout.copyWith(color: dxLabel);

  TextStyle get dxCaption => dxTypography.caption1.copyWith(color: dxSecondary);

  TextStyle get dxSectionLabel => dxTypography.footnote.copyWith(
        fontWeight: FontWeight.w600,
        color: dxSecondary,
      );

  TextStyle get dxFieldPrefix => dxTypography.footnote.copyWith(color: dxSecondary);
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    final secondary = MacosColors.secondaryLabelColor.resolveFrom(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: MacosTheme.of(context)
                      .primaryColor
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: MacosIcon(
                    icon,
                    size: 32,
                    color: MacosTheme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: typography.title2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: typography.body.copyWith(color: secondary, height: 1.35),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                SleekButton.label(
                  label: actionLabel!,
                  onPressed: onAction,
                  size: SleekButtonSize.large,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.brightnessOf(context) == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? MacosColors.controlBackgroundColor.resolveFrom(context)
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: MacosColors.separatorColor.withValues(alpha: 0.55),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: DefaultTextStyle(
        style: MacosTheme.of(context).typography.body.copyWith(
              color: MacosColors.labelColor.resolveFrom(context),
            ),
        child: IconTheme(
          data: IconThemeData(
            color: MacosColors.labelColor.resolveFrom(context),
            size: 16,
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    final secondary = MacosColors.secondaryLabelColor.resolveFrom(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: typography.title3),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: typography.caption1.copyWith(color: secondary),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class HoverSurface extends StatefulWidget {
  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  const HoverSurface({
    super.key,
    required this.child,
    this.selected = false,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  @override
  State<HoverSurface> createState() => _HoverSurfaceState();
}

class _HoverSurfaceState extends State<HoverSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = MacosTheme.of(context).primaryColor;
    final isDark = MacosTheme.brightnessOf(context) == Brightness.dark;

    Color background;
    if (widget.selected) {
      background = primary.withValues(alpha: isDark ? 0.22 : 0.12);
    } else if (_hovered) {
      background = (isDark ? CupertinoColors.white : CupertinoColors.black)
          .withValues(alpha: isDark ? 0.06 : 0.04);
    } else {
      background = MacosColors.transparent;
    }

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: background,
            borderRadius: widget.borderRadius,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
