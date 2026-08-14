import 'dart:io';
import 'dart:convert';
import 'package:googleapis/androidpublisher/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
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
    final credentials = jsonDecode(credentialsJson);

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
    final results = await _db.query('service_accounts', orderBy: 'added_at DESC');
    return results.map((data) => _mapToServiceAccount(data)).toList();
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

  Future<AndroidPublisherApi> _getPublisherApi(String accountId) async {
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

    return AndroidPublisherApi(client);
  }

  Future<void> uploadToPlayStore({
    required String accountId,
    required String packageName,
    required String aabPath,
    required PublishConfig config,
  }) async {
    final api = await _getPublisherApi(accountId);
    
    final aabFile = File(aabPath);
    if (!await aabFile.exists()) {
      throw Exception('AAB file not found: $aabPath');
    }

    final edit = await api.edits.insert(AppEdit(), packageName);
    final editId = edit.id!;

    try {
      final bundle = await aabFile.readAsBytes();
      
      final uploadRequest = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/$packageName/edits/$editId/bundles',
        ),
      );
      uploadRequest.files.add(
        http.MultipartFile.fromBytes('file', bundle, filename: 'bundle.aab'),
      );

      await api.edits.tracks.update(
        Track(
          track: config.track.name,
          releases: [
            TrackRelease(
              name: config.releaseNotes,
              status: 'completed',
              releaseNotes: [
                LocalizedText(
                  language: 'en-US',
                  text: config.releaseNotes,
                ),
              ],
              userFraction: config.userFraction,
            ),
          ],
        ),
        packageName,
        editId,
        config.track.name,
      );

      await api.edits.commit(packageName, editId);
    } catch (e) {
      await api.edits.delete(packageName, editId);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAppInfo(
    String accountId,
    String packageName,
  ) async {
    final api = await _getPublisherApi(accountId);
    
    try {
      final appDetails = await api.applications.get(packageName);
      return {
        'packageName': packageName,
        'title': appDetails.title,
        'defaultLanguage': appDetails.defaultLanguage,
      };
    } catch (e) {
      throw Exception('Failed to fetch app info: $e');
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
