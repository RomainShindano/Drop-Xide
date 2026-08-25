import 'dart:async';
import 'dart:convert';
import 'dart:io';

class GitService {
  /// Get list of local branches for a project
  Future<List<String>> getBranches(String projectPath) async {
    try {
      final result = await Process.run(
        'git',
        ['branch', '--format=%(refname:short)'],
        workingDirectory: projectPath,
      );

      if (result.exitCode != 0) {
        throw Exception('Failed to list branches: ${result.stderr}');
      }

      final branches = (result.stdout as String)
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      return branches;
    } catch (e) {
      throw Exception('Error fetching branches: $e');
    }
  }

  /// Get current branch name
  Future<String?> getCurrentBranch(String projectPath) async {
    try {
      final result = await Process.run(
        'git',
        ['branch', '--show-current'],
        workingDirectory: projectPath,
      );

      if (result.exitCode != 0) {
        return null;
      }

      final branch = (result.stdout as String).trim();
      return branch.isEmpty ? null : branch;
    } catch (e) {
      return null;
    }
  }

  /// Check if the project is a Git repository
  Future<bool> isGitRepository(String projectPath) async {
    try {
      final result = await Process.run(
        'git',
        ['rev-parse', '--git-dir'],
        workingDirectory: projectPath,
      );

      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Checkout a specific branch
  Future<void> checkoutBranch(String projectPath, String branch) async {
    try {
      // First, check if there are uncommitted changes
      final statusResult = await Process.run(
        'git',
        ['status', '--porcelain'],
        workingDirectory: projectPath,
      );

      final hasChanges = (statusResult.stdout as String).trim().isNotEmpty;

      if (hasChanges) {
        // Stash changes before switching
        await Process.run(
          'git',
          ['stash', 'push', '-m', 'Auto-stash before build'],
          workingDirectory: projectPath,
        );
      }

      // Checkout the branch
      final checkoutResult = await Process.run(
        'git',
        ['checkout', branch],
        workingDirectory: projectPath,
      );

      if (checkoutResult.exitCode != 0) {
        throw Exception('Failed to checkout branch: ${checkoutResult.stderr}');
      }

      // Pull latest changes
      await Process.run(
        'git',
        ['pull', '--ff-only'],
        workingDirectory: projectPath,
      );
    } catch (e) {
      throw Exception('Error checking out branch: $e');
    }
  }

  /// Get both local and remote branches
  Future<List<String>> getAllBranches(String projectPath) async {
    try {
      // Fetch from remote
      await Process.run(
        'git',
        ['fetch', '--prune'],
        workingDirectory: projectPath,
      );

      final result = await Process.run(
        'git',
        ['branch', '-a', '--format=%(refname:short)'],
        workingDirectory: projectPath,
      );

      if (result.exitCode != 0) {
        throw Exception('Failed to list branches: ${result.stderr}');
      }

      final branches = (result.stdout as String)
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .map((line) {
            // Remove "origin/" prefix from remote branches for display
            if (line.startsWith('origin/')) {
              return line.substring(7);
            }
            return line;
          })
          .toSet() // Remove duplicates
          .toList();

      branches.sort();
      return branches;
    } catch (e) {
      // Fallback to local branches only
      return getBranches(projectPath);
    }
  }
}
