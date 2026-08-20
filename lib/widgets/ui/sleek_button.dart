import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

/// Compact / regular / large sleek action buttons for DropXide.
enum SleekButtonSize { small, regular, large }

class SleekButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool destructive;
  final SleekButtonSize size;
  final IconData? leadingIcon;
  final bool expanded;

  const SleekButton({
    super.key,
    required this.child,
    this.onPressed,
    this.secondary = false,
    this.destructive = false,
    this.size = SleekButtonSize.regular,
    this.leadingIcon,
    this.expanded = false,
  });

  factory SleekButton.label({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    bool secondary = false,
    bool destructive = false,
    SleekButtonSize size = SleekButtonSize.regular,
    IconData? leadingIcon,
    bool expanded = false,
  }) {
    return SleekButton(
      key: key,
      onPressed: onPressed,
      secondary: secondary,
      destructive: destructive,
      size: size,
      leadingIcon: leadingIcon,
      expanded: expanded,
      child: Text(label),
    );
  }

  @override
  State<SleekButton> createState() => _SleekButtonState();
}

class _SleekButtonState extends State<SleekButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  EdgeInsets get _padding {
    switch (widget.size) {
      case SleekButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 5);
      case SleekButtonSize.regular:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 7);
      case SleekButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 11);
    }
  }

  double get _radius {
    switch (widget.size) {
      case SleekButtonSize.small:
        return 7;
      case SleekButtonSize.regular:
        return 8;
      case SleekButtonSize.large:
        return 10;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case SleekButtonSize.small:
        return 12;
      case SleekButtonSize.regular:
        return 13;
      case SleekButtonSize.large:
        return 14;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case SleekButtonSize.small:
        return 12;
      case SleekButtonSize.regular:
        return 14;
      case SleekButtonSize.large:
        return 15;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MacosTheme.brightnessOf(context) == Brightness.dark;
    final accent = MacosTheme.of(context).primaryColor;
    final danger = MacosColors.systemRedColor;

    final Color base;
    final Color textColor;
    List<BoxShadow>? shadows;
    Border? border;
    Gradient? gradient;

    if (!_enabled) {
      base = isDark
          ? CupertinoColors.white.withValues(alpha: 0.06)
          : CupertinoColors.black.withValues(alpha: 0.05);
      textColor = MacosColors.secondaryLabelColor.resolveFrom(context);
      border = null;
      gradient = null;
      shadows = null;
    } else if (widget.secondary) {
      final hoverBoost = _hovered ? 0.04 : 0.0;
      base = isDark
          ? CupertinoColors.white.withValues(alpha: 0.08 + hoverBoost)
          : CupertinoColors.black.withValues(alpha: 0.045 + hoverBoost);
      textColor = widget.destructive
          ? danger
          : MacosColors.labelColor.resolveFrom(context);
      border = Border.all(
        color: isDark
            ? CupertinoColors.white.withValues(alpha: 0.12)
            : CupertinoColors.black.withValues(alpha: 0.08),
      );
      gradient = null;
      shadows = null;
    } else {
      final accentColor = widget.destructive ? danger : accent;
      final top = Color.lerp(
            accentColor,
            CupertinoColors.white,
            _hovered ? 0.14 : 0.08,
          ) ??
          accentColor;
      final bottom = Color.lerp(
            accentColor,
            CupertinoColors.black,
            _hovered ? 0.04 : 0.1,
          ) ??
          accentColor;
      base = accentColor;
      textColor = CupertinoColors.white;
      gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, bottom],
      );
      border = Border.all(
        color: accentColor.withValues(alpha: 0.35),
      );
      shadows = [
        BoxShadow(
          color: accentColor.withValues(alpha: isDark ? 0.35 : 0.28),
          blurRadius: _hovered ? 14 : 10,
          offset: const Offset(0, 3),
        ),
      ];
    }

    final content = DefaultTextStyle(
      style: TextStyle(
        color: textColor,
        fontSize: _fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        height: 1.1,
      ),
      child: IconTheme(
        data: IconThemeData(color: textColor, size: _iconSize),
        child: Row(
          mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.leadingIcon != null) ...[
              Icon(widget.leadingIcon, size: _iconSize, color: textColor),
              const SizedBox(width: 6),
            ],
            Flexible(child: widget.child),
          ],
        ),
      ),
    );

    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (_enabled) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed && _enabled ? 0.97 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            width: widget.expanded ? double.infinity : null,
            padding: _padding,
            decoration: BoxDecoration(
              color: gradient == null ? base : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(_radius),
              border: border,
              boxShadow: shadows,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
