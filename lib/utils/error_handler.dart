import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

class ErrorHandler {
  static Future<void> showErrorSnackBar(
    BuildContext context,
    String message,
  ) {
    return _showAlert(
      context,
      title: 'Error',
      message: message,
      icon: CupertinoIcons.exclamationmark_circle_fill,
      iconColor: MacosColors.systemRedColor,
    );
  }

  static Future<void> showSuccessSnackBar(
    BuildContext context,
    String message,
  ) {
    return _showAlert(
      context,
      title: 'Success',
      message: message,
      icon: CupertinoIcons.checkmark_circle_fill,
      iconColor: MacosColors.systemGreenColor,
    );
  }

  static Future<void> showWarningSnackBar(
    BuildContext context,
    String message,
  ) {
    return _showAlert(
      context,
      title: 'Warning',
      message: message,
      icon: CupertinoIcons.exclamationmark_triangle_fill,
      iconColor: MacosColors.systemOrangeColor,
    );
  }

  static Future<void> showInfoSnackBar(
    BuildContext context,
    String message,
  ) {
    return _showAlert(
      context,
      title: 'Info',
      message: message,
      icon: CupertinoIcons.info_circle_fill,
      iconColor: MacosColors.systemBlueColor,
    );
  }

  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showMacosAlertDialog<bool>(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: MacosIcon(
          isDangerous
              ? CupertinoIcons.exclamationmark_triangle_fill
              : CupertinoIcons.question_circle_fill,
          size: 64,
          color: isDangerous
              ? MacosColors.systemOrangeColor
              : MacosColors.systemBlueColor,
        ),
        title: Text(
          title,
          style: MacosTheme.of(context).typography.headline,
        ),
        message: Text(message, textAlign: TextAlign.center),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          color: isDangerous ? MacosColors.systemRedColor : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
      ),
    );

    return result ?? false;
  }

  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? details,
  }) {
    final body = details == null ? message : '$message\n\n$details';
    return _showAlert(
      context,
      title: title,
      message: body,
      icon: CupertinoIcons.exclamationmark_circle_fill,
      iconColor: MacosColors.systemRedColor,
    );
  }

  static Future<void> _showAlert(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    return showMacosAlertDialog(
      context: context,
      builder: (_) => MacosAlertDialog(
        appIcon: MacosIcon(icon, size: 64, color: iconColor),
        title: Text(
          title,
          style: MacosTheme.of(context).typography.headline,
        ),
        message: Text(message, textAlign: TextAlign.center),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ),
    );
  }
}
