import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:googleapis/androidpublisher/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io';

import '../models/google_service_account.dart';
import 'database_service.dart';

class GooglePlayService {
  final DatabaseService _db = DatabaseService.instance;
  final _uuid = const Uuid();

  Future<GoogleServiceAccount> addServiceAccount(
    String name,
    String credentialsPath,
  ) async {
    final credentialsFile = File(credentialsPath);
    if (!await credentialsFile.exists()) {
      throw Exception('Credentials file not found');
    }

    final credentialsJson = await credentialsFile.readAsString();
    final credentials = jsonDecode(credentialsJson) as Map<String, dynamic>;

    if (credentials['client_email'] == null ||
        credentials['project_id'] == null ||
        credentials['private_key'] == null) {
      throw Exception('Invalid service account JSON');
    }

    final serviceAccount = GoogleServiceAccount(
      id: _uuid.v4(),
      name: name,
      email: credentials['client_email'] as String,
      projectId: credentials['project_id'] as String,
      addedAt: DateTime.now(),
      isActive: true,
    );

    await _db.insert('service_accounts', {
      'id': serviceAccount.id,
      'name': serviceAccount.name,
      'email': serviceAccount.email,
      'project_id': serviceAccount.projectId,
      'added_at': serviceAccount.addedAt.millisecondsSinceEpoch,
      'is_active': serviceAccount.isActive ? 1 : 0,
      'credentials': credentialsJson,
    });

    return serviceAccount;
  }

  Future<List<GoogleServiceAccount>> getServiceAccounts() async {
    final results =
        await _db.query('service_accounts', orderBy: 'added_at DESC');
    return results.map(_mapToServiceAccount).toList();
  }

  Future<GoogleServiceAccount?> getServiceAccount(String id) async {
    final results = await _db.query(
      'service_accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return _mapToServiceAccount(results.first);
  }

  Future<void> updateServiceAccount(GoogleServiceAccount account) async {
    await _db.update(
      'service_accounts',
      {
        'name': account.name,
        'email': account.email,
        'project_id': account.projectId,
        'is_active': account.isActive ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> deleteServiceAccount(String id) async {
    await _db.delete('service_accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<({AndroidPublisherApi api, http.Client client})> _getPublisherApi(
    String accountId,
  ) async {
    final results = await _db.query(
      'service_accounts',
      where: 'id = ?',
      whereArgs: [accountId],
    );

    if (results.isEmpty) {
      throw Exception('Service account not found');
    }

    final credentialsJson = results.first['credentials'] as String;
    final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
    final scopes = [AndroidPublisherApi.androidpublisherScope];
    final client = await clientViaServiceAccount(credentials, scopes);

    return (api: AndroidPublisherApi(client), client: client);
  }

  Future<void> uploadToPlayStore({
    required String accountId,
    required String packageName,
    required String aabPath,
    required PublishConfig config,
  }) async {
    final session = await _getPublisherApi(accountId);
    final api = session.api;
    final client = session.client;

    try {
      final aabFile = File(aabPath);
      if (!await aabFile.exists()) {
        throw Exception('AAB file not found: $aabPath');
      }

      final edit = await api.edits.insert(AppEdit(), packageName);
      final editId = edit.id!;

      try {
        final length = await aabFile.length();
        final media = commons.Media(
          aabFile.openRead(),
          length,
          contentType: 'application/octet-stream',
        );

        final bundle = await api.edits.bundles.upload(
          packageName,
          editId,
          uploadMedia: media,
        );

        final versionCode = bundle.versionCode;
        final isStaged =
            config.userFraction != null && config.userFraction! < 1.0;

        await api.edits.tracks.update(
          Track(
            track: config.track.name,
            releases: [
              TrackRelease(
                name: config.releaseNotes,
                status: isStaged ? 'inProgress' : 'completed',
                versionCodes: versionCode != null
                    ? [versionCode.toString()]
                    : null,
                releaseNotes: [
                  LocalizedText(
                    language: 'en-US',
                    text: config.releaseNotes,
                  ),
                ],
                userFraction: isStaged ? config.userFraction : null,
              ),
            ],
          ),
          packageName,
          editId,
          config.track.name,
        );

        await api.edits.commit(packageName, editId);
      } catch (e) {
        try {
          await api.edits.delete(packageName, editId);
        } catch (_) {}
        rethrow;
      }
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> getAppInfo(
    String accountId,
    String packageName,
  ) async {
    final session = await _getPublisherApi(accountId);
    final api = session.api;
    final client = session.client;

    try {
      final edit = await api.edits.insert(AppEdit(), packageName);
      final editId = edit.id!;
      try {
        final details = await api.edits.details.get(packageName, editId);
        return {
          'packageName': packageName,
          'title': details.defaultLanguage,
          'contactEmail': details.contactEmail,
          'contactWebsite': details.contactWebsite,
        };
      } finally {
        await api.edits.delete(packageName, editId);
      }
    } finally {
      client.close();
    }
  }

  GoogleServiceAccount _mapToServiceAccount(Map<String, dynamic> data) {
    return GoogleServiceAccount(
      id: data['id'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      projectId: data['project_id'] as String,
      addedAt: DateTime.fromMillisecondsSinceEpoch(data['added_at'] as int),
      isActive: (data['is_active'] as int) == 1,
    );
  }
}
