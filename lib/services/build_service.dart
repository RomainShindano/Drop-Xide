import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/flutter_project.dart';
import '../models/build_history.dart';
import 'database_service.dart';
import 'project_service.dart';

class BuildService {
  final DatabaseService _db = DatabaseService.instance;
  final ProjectService _projectService = ProjectService();
  final _uuid = const Uuid();
  
  final _buildStreamController = StreamController<BuildHistory>.broadcast();
  final _logStreamController = StreamController<String>.broadcast();

  Stream<BuildHistory> get buildStream => _buildStreamController.stream;
  Stream<String> get logStream => _logStreamController.stream;

  Future<BuildHistory> startBuild(
    FlutterProject project,
    BuildConfig config,
  ) async {
    final buildHistory = BuildHistory(
      id: _uuid.v4(),
      projectId: project.id,
      projectName: project.name,
      buildConfig: config,
      startedAt: DateTime.now(),
      status: BuildStatus.running,
      logs: [],
    );

    await _saveBuildHistory(buildHistory);
    _buildStreamController.add(buildHistory);

    _executeBuild(buildHistory, project).catchError((error) {
      _logStreamController.addError(error);
    });

    return buildHistory;
  }

  Future<void> _executeBuild(
    BuildHistory buildHistory,
    FlutterProject project,
  ) async {
    try {
      final config = buildHistory.buildConfig;
      final outputDir = await _getOutputDirectory(project.name);
      
      final shell = Shell(
        workingDirectory: project.path,
        verbose: false,
      );

      _addLog(buildHistory.id, 'Starting build for ${project.name}...');
      _addLog(buildHistory.id, 'Platform: ${config.platform.name}');
      _addLog(buildHistory.id, 'Mode: ${config.mode.name}');
      _addLog(buildHistory.id, 'Output directory: $outputDir');

      final command = _buildFlutterCommand(config, outputDir);
      _addLog(buildHistory.id, 'Running: $command');

      await for (final output in shell.run(command)) {
        final log = output.stdout.toString();
        if (log.isNotEmpty) {
          _addLog(buildHistory.id, log);
        }
        final errorLog = output.stderr.toString();
        if (errorLog.isNotEmpty) {
          _addLog(buildHistory.id, 'ERROR: $errorLog');
        }
      }

      final updatedBuild = buildHistory.copyWith(
        status: BuildStatus.success,
        completedAt: DateTime.now(),
        outputPath: outputDir,
      );

      await _updateBuildHistory(updatedBuild);
      _buildStreamController.add(updatedBuild);

      await _projectService.updateProject(
        project.copyWith(
          lastBuildAt: DateTime.now(),
          lastBuildConfig: config,
        ),
      );

      _addLog(buildHistory.id, 'Build completed successfully!');
    } catch (e) {
      final errorMessage = e.toString();
      _addLog(buildHistory.id, 'Build failed: $errorMessage');

      final updatedBuild = buildHistory.copyWith(
        status: BuildStatus.failed,
        completedAt: DateTime.now(),
        errorMessage: errorMessage,
      );

      await _updateBuildHistory(updatedBuild);
      _buildStreamController.add(updatedBuild);
    }
  }

  String _buildFlutterCommand(BuildConfig config, String outputDir) {
    final buffer = StringBuffer('flutter build ');

    switch (config.platform) {
      case BuildPlatform.android:
        buffer.write('apk ');
        break;
      case BuildPlatform.ios:
        buffer.write('ios ');
        break;
      case BuildPlatform.web:
        buffer.write('web ');
        break;
      case BuildPlatform.linux:
        buffer.write('linux ');
        break;
      case BuildPlatform.macos:
        buffer.write('macos ');
        break;
      case BuildPlatform.windows:
        buffer.write('windows ');
        break;
    }

    switch (config.mode) {
      case BuildMode.debug:
        buffer.write('--debug ');
        break;
      case BuildMode.profile:
        buffer.write('--profile ');
        break;
      case BuildMode.release:
        buffer.write('--release ');
        break;
    }

    if (config.flavor != null) {
      buffer.write('--flavor ${config.flavor} ');
    }

    if (config.obfuscate) {
      buffer.write('--obfuscate ');
    }

    if (config.splitDebugInfo) {
      buffer.write('--split-debug-info=$outputDir/debug-info ');
    }

    return buffer.toString().trim();
  }

  Future<String> _getOutputDirectory(String projectName) async {
    final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
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

  void _addLog(String buildId, String message) {
    _logStreamController.add('[$buildId] $message');
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

    return results.map((data) => _mapToBuildHistory(data)).toList();
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
  }

  BuildHistory _mapToBuildHistory(Map<String, dynamic> data) {
    return BuildHistory(
      id: data['id'] as String,
      projectId: data['project_id'] as String,
      projectName: data['project_name'] as String,
      buildConfig: BuildConfig.fromJson(jsonDecode(data['build_config'] as String)),
      startedAt: DateTime.fromMillisecondsSinceEpoch(data['started_at'] as int),
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
    _buildStreamController.close();
    _logStreamController.close();
  }
}
