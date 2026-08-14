import 'package:flutter/foundation.dart';
import '../models/flutter_project.dart';
import '../services/project_service.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectService _projectService = ProjectService();
  
  List<FlutterProject> _projects = [];
  FlutterProject? _selectedProject;
  bool _isLoading = false;
  String? _error;

  List<FlutterProject> get projects => _projects;
  FlutterProject? get selectedProject => _selectedProject;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _projects = await _projectService.getProjects();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProject(String path) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final project = await _projectService.addProject(path);
      _projects.insert(0, project);
      _selectedProject = project;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProject(FlutterProject project) async {
    try {
      await _projectService.updateProject(project);
      final index = _projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        _projects[index] = project;
        if (_selectedProject?.id == project.id) {
          _selectedProject = project;
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _projectService.deleteProject(id);
      _projects.removeWhere((p) => p.id == id);
      if (_selectedProject?.id == id) {
        _selectedProject = null;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void selectProject(FlutterProject? project) {
    _selectedProject = project;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
