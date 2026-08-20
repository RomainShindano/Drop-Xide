import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

class AppTheme {
  static MacosThemeData get light => MacosThemeData.light(
        accentColor: AccentColor.blue,
      ).copyWith(
        pushButtonTheme: const PushButtonThemeData(
          color: Color(0xFF007AFF),
          disabledColor: Color(0x33007AFF),
          secondaryColor: Color(0x14000000),
        ),
      );

  static MacosThemeData get dark => MacosThemeData.dark(
        accentColor: AccentColor.blue,
      ).copyWith(
        pushButtonTheme: const PushButtonThemeData(
          color: Color(0xFF0A84FF),
          disabledColor: Color(0x330A84FF),
          secondaryColor: Color(0x22FFFFFF),
        ),
      );
}
