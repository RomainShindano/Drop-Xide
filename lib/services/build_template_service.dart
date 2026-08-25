import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/build_template.dart';
import '../models/flutter_project.dart';
import '../services/database_service.dart';

class BuildTemplateService {
  final DatabaseService _db = DatabaseService.instance;
  final _uuid = const Uuid();

  Future<List<BuildTemplate>> getTemplates() async {
    final results = await _db.query(
      'build_templates',
      orderBy: 'is_favorite DESC, last_used_at DESC',
    );
    return results.map((data) => _mapToTemplate(data)).toList();
  }

  Future<BuildTemplate?> getTemplate(String id) async {
    final results = await _db.query(
      'build_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return _mapToTemplate(results.first);
  }

  Future<BuildTemplate> saveTemplate({
    required String name,
    String? description,
    required BuildConfig buildConfig,
  }) async {
    final template = BuildTemplate(
      id: _uuid.v4(),
      name: name,
      description: description,
      buildConfig: buildConfig,
      createdAt: DateTime.now(),
    );

    await _db.insert('build_templates', _templateToMap(template));
    return template;
  }

  Future<void> updateTemplate(BuildTemplate template) async {
    await _db.update(
      'build_templates',
      _templateToMap(template),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<void> deleteTemplate(String id) async {
    await _db.delete(
      'build_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementUsageCount(String id) async {
    final template = await getTemplate(id);
    if (template != null) {
      final updated = template.copyWith(
        usageCount: template.usageCount + 1,
        lastUsedAt: DateTime.now(),
      );
      await updateTemplate(updated);
    }
  }

  Future<void> toggleFavorite(String id) async {
    final template = await getTemplate(id);
    if (template != null) {
      final updated = template.copyWith(isFavorite: !template.isFavorite);
      await updateTemplate(updated);
    }
  }

  BuildTemplate _mapToTemplate(Map<String, dynamic> data) {
    return BuildTemplate(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      buildConfig: BuildConfig.fromJson(jsonDecode(data['build_config'] as String)),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] as int),
      lastUsedAt: data['last_used_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['last_used_at'] as int)
          : null,
      usageCount: data['usage_count'] as int,
      isFavorite: (data['is_favorite'] as int) == 1,
    );
  }

  Map<String, dynamic> _templateToMap(BuildTemplate template) {
    return {
      'id': template.id,
      'name': template.name,
      'description': template.description,
      'build_config': jsonEncode(template.buildConfig.toJson()),
      'created_at': template.createdAt.millisecondsSinceEpoch,
      'last_used_at': template.lastUsedAt?.millisecondsSinceEpoch,
      'usage_count': template.usageCount,
      'is_favorite': template.isFavorite ? 1 : 0,
    };
  }
}
