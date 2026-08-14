import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:uuid/uuid.dart';
import '../models/flutter_project.dart';
import '../models/build_history.dart';
import 'database_service.dart';

class ProjectService {
  final DatabaseService _db = DatabaseService.instance;
  final _uuid = const Uuid();

  Future<List<FlutterProject>> getProjects() async {
    final results = await _db.query('projects', orderBy: 'added_at DESC');
    return results.map((data) => _mapToProject(data)).toList();
  }

  Future<FlutterProject?> getProject(String id) async {
    final results = await _db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return _mapToProject(results.first);
  }

  Future<FlutterProject> addProject(String projectPath) async {
    final projectInfo = await _validateAndReadProject(projectPath);
    
    final project = FlutterProject(
      id: _uuid.v4(),
      name: projectInfo['name'] as String,
      path: projectPath,
      description: projectInfo['description'] as String?,
      addedAt: DateTime.now(),
    );

    await _db.insert('projects', _projectToMap(project));
    return project;
  }

  Future<void> updateProject(FlutterProject project) async {
    await _db.update(
      'projects',
      _projectToMap(project),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<void> deleteProject(String id) async {
    await _db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> _validateAndReadProject(String projectPath) async {
    final pubspecPath = path.join(projectPath, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);

    if (!await pubspecFile.exists()) {
      throw Exception('Not a valid Flutter project: pubspec.yaml not found');
    }

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content);

    if (yaml is! YamlMap) {
      throw Exception('Invalid pubspec.yaml format');
    }

    final dependencies = yaml['dependencies'];
    if (dependencies == null || dependencies['flutter'] == null) {
      throw Exception('Not a Flutter project: flutter dependency not found');
    }

    return {
      'name': yaml['name'] as String,
      'description': yaml['description'] as String?,
      'version': yaml['version'] as String?,
    };
  }

  Future<bool> validateFlutterProject(String projectPath) async {
    try {
      await _validateAndReadProject(projectPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  FlutterProject _mapToProject(Map<String, dynamic> data) {
    return FlutterProject(
      id: data['id'] as String,
      name: data['name'] as String,
      path: data['path'] as String,
      description: data['description'] as String?,
      addedAt: DateTime.fromMillisecondsSinceEpoch(data['added_at'] as int),
      lastBuildAt: data['last_build_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['last_build_at'] as int)
          : null,
      lastBuildConfig: data['last_build_config'] != null
          ? BuildConfig.fromJson(jsonDecode(data['last_build_config'] as String))
          : null,
    );
  }

  Map<String, dynamic> _projectToMap(FlutterProject project) {
    return {
      'id': project.id,
      'name': project.name,
      'path': project.path,
      'description': project.description,
      'added_at': project.addedAt.millisecondsSinceEpoch,
      'last_build_at': project.lastBuildAt?.millisecondsSinceEpoch,
      'last_build_config': project.lastBuildConfig != null
          ? jsonEncode(project.lastBuildConfig!.toJson())
          : null,
    };
  }
}
