import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/project_provider.dart';
import 'providers/build_provider.dart';
import 'providers/publish_provider.dart';
import 'providers/settings_provider.dart';
import 'constants/app_theme.dart';

Future<void> _configureMacosWindowUtils() async {
  const config = MacosWindowUtilsConfig(
    toolbarStyle: NSWindowToolbarStyle.unified,
  );
  await config.apply();

  await WindowManipulator.setWindowFrame(
    const Rect.fromLTWH(120, 80, 900, 620),
    animate: false,
  );
  await WindowManipulator.setWindowMinSize(const Size(900, 620));
}

void main() async {
  await _configureMacosWindowUtils();

  final projectProvider = ProjectProvider()..loadProjects();
  final buildProvider = BuildProvider()..loadBuildHistory();
  final publishProvider = PublishProvider()..loadPublishHistory();
  buildProvider.onProjectUpdated = projectProvider.applyLocalUpdate;

  runApp(
    MyApp(
      projectProvider: projectProvider,
      buildProvider: buildProvider,
      publishProvider: publishProvider,
    ),
  );
}

class MyApp extends StatelessWidget {
  final ProjectProvider projectProvider;
  final BuildProvider buildProvider;
  final PublishProvider publishProvider;

  const MyApp({
    super.key,
    required this.projectProvider,
    required this.buildProvider,
    required this.publishProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: projectProvider),
        ChangeNotifierProvider.value(value: buildProvider),
        ChangeNotifierProvider.value(value: publishProvider),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..load(),
        ),
      ],
      child: MacosApp(
        title: 'DropXide',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
