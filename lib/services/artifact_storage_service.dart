import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';

class ArtifactStorageService {
  static final ArtifactStorageService instance = ArtifactStorageService._internal();
  final DatabaseService _db = DatabaseService.instance;

  ArtifactStorageService._internal();

  /// Get the base artifacts directory
  Future<Directory> getArtifactsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final artifactsDir = Directory(path.join(appDir.path, 'Drop-Xide', 'artifacts'));
    
    if (!await artifactsDir.exists()) {
      await artifactsDir.create(recursive: true);
    }
    
    return artifactsDir;
  }

  /// Get project-specific artifacts directory
  Future<Directory> getProjectArtifactsDirectory(String projectId) async {
    final artifactsDir = await getArtifactsDirectory();
    final projectDir = Directory(path.join(artifactsDir.path, projectId));
    
    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
    }
    
    return projectDir;
  }

  /// Get the next build number for a project
  Future<int> getNextBuildNumber(String projectId) async {
    final results = await _db.query(
      'build_history',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'build_number DESC',
      limit: 1,
    );

    if (results.isEmpty) {
      return 1;
    }

    final lastBuildNumber = results.first['build_number'] as int;
    return lastBuildNumber + 1;
  }

  /// Store build artifact with versioning
  Future<String?> storeArtifact({
    required String projectId,
    required String projectName,
    required int buildNumber,
    required String sourcePath,
    required String platform,
    required String mode,
  }) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return null;
      }

      final projectDir = await getProjectArtifactsDirectory(projectId);
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final extension = path.extension(sourcePath);
      
      // Format: {projectName}-v{buildNumber}-{platform}-{mode}-{timestamp}{ext}
      final fileName = '${projectName.replaceAll(' ', '_')}-v$buildNumber-$platform-$mode-$timestamp$extension';
      final destPath = path.join(projectDir.path, fileName);
      
      // Copy the artifact
      await sourceFile.copy(destPath);
      
      return destPath;
    } catch (e) {
      return null;
    }
  }

  /// Get artifact file size
  Future<int?> getArtifactSize(String artifactPath) async {
    try {
      final file = File(artifactPath);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// List all artifacts for a project
  Future<List<FileSystemEntity>> listProjectArtifacts(String projectId) async {
    try {
      final projectDir = await getProjectArtifactsDirectory(projectId);
      final artifacts = await projectDir.list().toList();
      
      // Sort by modification time (newest first)
      artifacts.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });
      
      return artifacts;
    } catch (e) {
      return [];
    }
  }

  /// Delete an artifact
  Future<bool> deleteArtifact(String artifactPath) async {
    try {
      final file = File(artifactPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Delete all artifacts for a project
  Future<bool> deleteProjectArtifacts(String projectId) async {
    try {
      final projectDir = await getProjectArtifactsDirectory(projectId);
      if (await projectDir.exists()) {
        await projectDir.delete(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get total storage used by all artifacts
  Future<int> getTotalStorageUsed() async {
    try {
      final artifactsDir = await getArtifactsDirectory();
      int totalSize = 0;
      
      await for (var entity in artifactsDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Format bytes to human-readable string
  String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Open artifact in system file manager
  Future<void> revealArtifact(String artifactPath) async {
    try {
      final file = File(artifactPath);
      if (await file.exists()) {
        if (Platform.isMacOS) {
          await Process.run('open', ['-R', artifactPath]);
        } else if (Platform.isWindows) {
          await Process.run('explorer', ['/select,', artifactPath]);
        } else if (Platform.isLinux) {
          // Open parent directory
          final parentDir = file.parent.path;
          await Process.run('xdg-open', [parentDir]);
        }
      }
    } catch (e) {
      // Silently fail
    }
  }
}
