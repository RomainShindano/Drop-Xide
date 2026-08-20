import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../models/build_history.dart';
import '../models/flutter_project.dart';
import 'database_service.dart';
import 'flutter_sdk_service.dart';
import 'project_service.dart';

class BuildService {
  final DatabaseService _db = DatabaseService.instance;
  final ProjectService _projectService = ProjectService();
  final FlutterSdkService _sdkService = FlutterSdkService();
  final _uuid = const Uuid();

  final _buildStreamController = StreamController<BuildHistory>.broadcast();
  final _logStreamController = StreamController<String>.broadcast();
  final _projectUpdateController = StreamController<FlutterProject>.broadcast();

  final Map<String, List<String>> _logsByBuild = {};
  Process? _activeProcess;
  String? _activeBuildId;

  Stream<BuildHistory> get buildStream => _buildStreamController.stream;
  Stream<String> get logStream => _logStreamController.stream;
  Stream<FlutterProject> get projectUpdateStream =>
      _projectUpdateController.stream;

  bool get isBuilding => _activeProcess != null;

  Future<BuildHistory> startBuild(
    FlutterProject project,
    BuildConfig config,
  ) async {
    if (_activeProcess != null) {
      throw Exception('A build is already running');
    }

    final sdkOk = await _sdkService.validateFlutterSdk();
    if (!sdkOk || _sdkService.flutterPath == null) {
      throw Exception(
        'Flutter SDK not found. Install Flutter and ensure it is on your PATH.',
      );
    }

    var effectiveConfig = config;
    if (config.obfuscate && !config.splitDebugInfo) {
      effectiveConfig = BuildConfig(
        mode: config.mode,
        platform: config.platform,
        buildType: config.buildType,
        flavor: config.flavor,
        obfuscate: true,
        splitDebugInfo: true,
      );
    }

    final buildHistory = BuildHistory(
      id: _uuid.v4(),
      projectId: project.id,
      projectName: project.name,
      buildConfig: effectiveConfig,
      startedAt: DateTime.now(),
      status: BuildStatus.running,
      logs: [],
    );

    _logsByBuild[buildHistory.id] = [];
    await _saveBuildHistory(buildHistory);
    _buildStreamController.add(buildHistory);

    unawaited(_executeBuild(buildHistory, project));

    return buildHistory;
  }

  Future<void> cancelBuild() async {
    final process = _activeProcess;
    final buildId = _activeBuildId;
    if (process == null || buildId == null) return;

    process.kill(ProcessSignal.sigterm);
    await _appendLog(buildId, 'Build cancelled by user.');
  }

  Future<void> _executeBuild(
    BuildHistory buildHistory,
    FlutterProject project,
  ) async {
    var current = buildHistory;
    final config = buildHistory.buildConfig;

    try {
      final outputDir = await _getOutputDirectory(project.name);
      final command = _buildFlutterArgs(config, outputDir);

      await _appendLog(current.id, 'Starting build for ${project.name}...');
      await _appendLog(current.id, 'Platform: ${config.platform.name}');
      await _appendLog(current.id, 'Mode: ${config.mode.name}');
      if (config.platform == BuildPlatform.android) {
        await _appendLog(
          current.id,
          'Type: ${config.effectiveBuildType.name}',
        );
      }
      await _appendLog(current.id, 'Output directory: $outputDir');
      await _appendLog(
        current.id,
        'Running: flutter ${command.join(' ')}',
      );

      final process = await Process.start(
        _sdkService.flutterPath!,
        command,
        workingDirectory: project.path,
        environment: Platform.environment,
        runInShell: false,
      );

      _activeProcess = process;
      _activeBuildId = current.id;

      final stdoutDone = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            if (line.trim().isNotEmpty) {
              unawaited(_appendLog(current.id, line));
            }
          })
          .asFuture<void>();

      final stderrDone = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            if (line.trim().isNotEmpty) {
              unawaited(_appendLog(current.id, line));
            }
          })
          .asFuture<void>();

      final exitCode = await process.exitCode;
      await Future.wait([stdoutDone, stderrDone]);

      _activeProcess = null;
      _activeBuildId = null;

      if (exitCode != 0) {
        throw Exception('flutter build exited with code $exitCode');
      }

      final artifactPath = await _collectArtifacts(
        buildId: current.id,
        project: project,
        config: config,
        outputDir: outputDir,
      );

      current = current.copyWith(
        status: BuildStatus.success,
        completedAt: DateTime.now(),
        outputPath: artifactPath ?? outputDir,
        logs: List.unmodifiable(_logsByBuild[current.id] ?? const []),
      );

      await _updateBuildHistory(current);
      _buildStreamController.add(current);

      final updatedProject = project.copyWith(
        lastBuildAt: DateTime.now(),
        lastBuildConfig: config,
      );
      await _projectService.updateProject(updatedProject);
      _projectUpdateController.add(updatedProject);

      await _appendLog(current.id, 'Build completed successfully!');
      await _persistLogs(current.id);
    } catch (e) {
      final buildId = current.id;
      final wasCancelled = _logsByBuild[buildId]
              ?.any((l) => l.contains('cancelled by user')) ??
          false;

      _activeProcess = null;
      _activeBuildId = null;

      final status =
          wasCancelled ? BuildStatus.cancelled : BuildStatus.failed;
      if (!wasCancelled) {
        await _appendLog(buildId, 'Build failed: $e');
      }

      current = current.copyWith(
        status: status,
        completedAt: DateTime.now(),
        errorMessage: wasCancelled ? 'Cancelled' : e.toString(),
        logs: List.unmodifiable(_logsByBuild[buildId] ?? const []),
      );

      await _updateBuildHistory(current);
      _buildStreamController.add(current);
    }
  }

  List<String> _buildFlutterArgs(BuildConfig config, String outputDir) {
    final args = <String>['build'];

    switch (config.platform) {
      case BuildPlatform.android:
        args.add(
          config.effectiveBuildType == BuildType.appbundle
              ? 'appbundle'
              : 'apk',
        );
      case BuildPlatform.ios:
        args.add('ipa');
      case BuildPlatform.web:
        args.add('web');
      case BuildPlatform.linux:
        args.add('linux');
      case BuildPlatform.macos:
        args.add('macos');
      case BuildPlatform.windows:
        args.add('windows');
    }

    switch (config.mode) {
      case BuildMode.debug:
        args.add('--debug');
      case BuildMode.profile:
        args.add('--profile');
      case BuildMode.release:
        args.add('--release');
    }

    if (config.flavor != null && config.flavor!.isNotEmpty) {
      args.addAll(['--flavor', config.flavor!]);
    }

    final needsSplit = config.obfuscate || config.splitDebugInfo;
    if (config.obfuscate) {
      args.add('--obfuscate');
    }
    if (needsSplit) {
      args.add('--split-debug-info=${path.join(outputDir, 'debug-info')}');
    }

    return args;
  }

  Future<String?> _collectArtifacts({
    required String buildId,
    required FlutterProject project,
    required BuildConfig config,
    required String outputDir,
  }) async {
    final sources = <String>[];

    switch (config.platform) {
      case BuildPlatform.android:
        if (config.effectiveBuildType == BuildType.appbundle) {
          sources.add(
            path.join(
              project.path,
              'build',
              'app',
              'outputs',
              'bundle',
              config.mode.name,
            ),
          );
        } else {
          sources.add(
            path.join(
              project.path,
              'build',
              'app',
              'outputs',
              'flutter-apk',
            ),
          );
          sources.add(
            path.join(
              project.path,
              'build',
              'app',
              'outputs',
              'apk',
              config.mode.name,
            ),
          );
        }
      case BuildPlatform.macos:
        sources.add(
          path.join(
            project.path,
            'build',
            'macos',
            'Build',
            'Products',
            config.mode.name == 'debug' ? 'Debug' : 'Release',
          ),
        );
      case BuildPlatform.ios:
        sources.add(path.join(project.path, 'build', 'ios', 'ipa'));
        sources.add(path.join(project.path, 'build', 'ios', 'iphoneos'));
      case BuildPlatform.web:
        sources.add(path.join(project.path, 'build', 'web'));
      case BuildPlatform.linux:
        sources.add(
          path.join(
            project.path,
            'build',
            'linux',
            'x64',
            config.mode.name,
            'bundle',
          ),
        );
      case BuildPlatform.windows:
        sources.add(
          path.join(
            project.path,
            'build',
            'windows',
            'x64',
            'runner',
            config.mode.name,
          ),
        );
    }

    final copied = <String>[];
    for (final sourcePath in sources) {
      final entityType = await FileSystemEntity.type(sourcePath);
      if (entityType == FileSystemEntityType.notFound) continue;

      if (entityType == FileSystemEntityType.directory) {
        final dir = Directory(sourcePath);
        await for (final entity in dir.list(recursive: false)) {
          if (entity is File) {
            final name = path.basename(entity.path);
            if (_isLikelyArtifact(name, config)) {
              final dest = path.join(outputDir, name);
              await entity.copy(dest);
              copied.add(dest);
            }
          } else if (entity is Directory && entity.path.endsWith('.app')) {
            final dest = path.join(outputDir, path.basename(entity.path));
            await _copyDirectory(entity, Directory(dest));
            copied.add(dest);
          }
        }

        if (config.platform == BuildPlatform.web ||
            config.platform == BuildPlatform.linux) {
          final dest = path.join(outputDir, path.basename(sourcePath));
          await _copyDirectory(dir, Directory(dest));
          copied.add(dest);
        }
      } else if (entityType == FileSystemEntityType.file) {
        final file = File(sourcePath);
        final dest = path.join(outputDir, path.basename(file.path));
        await file.copy(dest);
        copied.add(dest);
      }
    }

    if (copied.isEmpty) {
      await _appendLog(
        buildId,
        'Warning: no artifacts copied. Check the project build/ folder.',
      );
    } else {
      await _appendLog(
        buildId,
        'Copied ${copied.length} artifact(s) to $outputDir',
      );
    }

    return outputDir;
  }

  bool _isLikelyArtifact(String name, BuildConfig config) {
    final lower = name.toLowerCase();
    switch (config.platform) {
      case BuildPlatform.android:
        return lower.endsWith('.apk') || lower.endsWith('.aab');
      case BuildPlatform.ios:
        return lower.endsWith('.ipa') || lower.endsWith('.app');
      default:
        return true;
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      final newPath = path.join(destination.path, path.basename(entity.path));
      if (entity is File) {
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      }
    }
  }

  Future<String> _getOutputDirectory(String projectName) async {
    final homeDir =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (homeDir == null) {
      throw Exception('Could not determine home directory');
    }

    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final outputDir = path.join(homeDir, 'Dropxide', projectName, timestamp);

    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return outputDir;
  }

  Future<void> _appendLog(String buildId, String message) async {
    if (buildId.isEmpty) return;
    final logs = _logsByBuild.putIfAbsent(buildId, () => <String>[]);
    logs.add(message);
    _logStreamController.add(message);

    // Persist periodically (every 20 lines) so history survives crashes
    if (logs.length % 20 == 0) {
      await _persistLogs(buildId);
    }
  }

  Future<void> _persistLogs(String buildId) async {
    final logs = _logsByBuild[buildId];
    if (logs == null) return;

    final existing = await getBuild(buildId);
    if (existing == null) return;

    await _updateBuildHistory(existing.copyWith(logs: List.from(logs)));
  }

  Future<List<BuildHistory>> getBuildHistory({
    String? projectId,
    int limit = 50,
  }) async {
    final results = await _db.query(
      'build_history',
      where: projectId != null ? 'project_id = ?' : null,
      whereArgs: projectId != null ? [projectId] : null,
      orderBy: 'started_at DESC',
      limit: limit,
    );

    return results.map(_mapToBuildHistory).toList();
  }

  Future<BuildHistory?> getBuild(String id) async {
    final results = await _db.query(
      'build_history',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return _mapToBuildHistory(results.first);
  }

  Future<void> _saveBuildHistory(BuildHistory build) async {
    await _db.insert('build_history', _buildHistoryToMap(build));
  }

  Future<void> _updateBuildHistory(BuildHistory build) async {
    await _db.update(
      'build_history',
      _buildHistoryToMap(build),
      where: 'id = ?',
      whereArgs: [build.id],
    );
  }

  Future<void> deleteBuildHistory(String id) async {
    await _db.delete('build_history', where: 'id = ?', whereArgs: [id]);
    _logsByBuild.remove(id);
  }

  BuildHistory _mapToBuildHistory(Map<String, dynamic> data) {
    return BuildHistory(
      id: data['id'] as String,
      projectId: data['project_id'] as String,
      projectName: data['project_name'] as String,
      buildConfig:
          BuildConfig.fromJson(jsonDecode(data['build_config'] as String)),
      startedAt:
          DateTime.fromMillisecondsSinceEpoch(data['started_at'] as int),
      completedAt: data['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['completed_at'] as int)
          : null,
      status: BuildStatus.values.firstWhere(
        (e) => e.name == data['status'],
      ),
      outputPath: data['output_path'] as String?,
      errorMessage: data['error_message'] as String?,
      logs: data['logs'] != null
          ? List<String>.from(jsonDecode(data['logs'] as String))
          : [],
    );
  }

  Map<String, dynamic> _buildHistoryToMap(BuildHistory build) {
    return {
      'id': build.id,
      'project_id': build.projectId,
      'project_name': build.projectName,
      'build_config': jsonEncode(build.buildConfig.toJson()),
      'started_at': build.startedAt.millisecondsSinceEpoch,
      'completed_at': build.completedAt?.millisecondsSinceEpoch,
      'status': build.status.name,
      'output_path': build.outputPath,
      'error_message': build.errorMessage,
      'logs': jsonEncode(build.logs),
    };
  }

  void dispose() {
    _activeProcess?.kill(ProcessSignal.sigterm);
    _buildStreamController.close();
    _logStreamController.close();
    _projectUpdateController.close();
  }
}
