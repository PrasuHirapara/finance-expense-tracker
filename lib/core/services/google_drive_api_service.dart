import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/cloud_sync_models.dart';

class GoogleDriveApiService {
  GoogleDriveApiService();

  static const String appFolderName = 'Daily Use';
  static const String _folderMimeType = 'application/vnd.google-apps.folder';
  static final Uri _filesUri = Uri.parse(
    'https://www.googleapis.com/drive/v3/files',
  );

  Future<Map<String, String>> ensureFolderHierarchy(
    Map<String, String> authorizationHeaders,
  ) async {
    final root = await _ensureFolder(
      authorizationHeaders: authorizationHeaders,
      folderName: appFolderName,
    );
    final credential = await _ensureFolder(
      authorizationHeaders: authorizationHeaders,
      folderName: CloudSyncDomain.credential.folderName,
      parentId: root.id,
    );
    final expense = await _ensureFolder(
      authorizationHeaders: authorizationHeaders,
      folderName: CloudSyncDomain.expense.folderName,
      parentId: root.id,
    );
    final task = await _ensureFolder(
      authorizationHeaders: authorizationHeaders,
      folderName: CloudSyncDomain.task.folderName,
      parentId: root.id,
    );

    return <String, String>{
      appFolderName: root.id,
      CloudSyncDomain.credential.folderName: credential.id,
      CloudSyncDomain.expense.folderName: expense.id,
      CloudSyncDomain.task.folderName: task.id,
    };
  }

  Future<DriveFileResource?> findChildByName({
    required Map<String, String> authorizationHeaders,
    required String folderName,
    String? parentId,
    String? mimeType,
  }) async {
    final queryParts = <String>[
      "name = '${_escapeQueryValue(folderName)}'",
      'trashed = false',
      if (parentId != null) "'$parentId' in parents",
      if (mimeType != null) "mimeType = '${_escapeQueryValue(mimeType)}'",
    ];
    final uri = _filesUri.replace(
      queryParameters: <String, String>{
        'q': queryParts.join(' and '),
        'fields': 'files(id,name,mimeType,modifiedTime,parents)',
        'pageSize': '10',
      },
    );
    final response = await _sendWithRetry(
      () => http.get(uri, headers: authorizationHeaders),
    );
    _throwIfError(response);

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final files = (decoded['files'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(DriveFileResource.fromJson)
        .toList(growable: false);
    return files.isEmpty ? null : files.first;
  }

  Future<void> uploadTextFile({
    required Map<String, String> authorizationHeaders,
    required String parentId,
    required String fileName,
    required String content,
  }) async {
    final existing = await findChildByName(
      authorizationHeaders: authorizationHeaders,
      folderName: fileName,
      parentId: parentId,
    );
    final isUpdate = existing != null;
    final metadata = <String, dynamic>{
      'name': fileName,
      if (!isUpdate) 'parents': <String>[parentId],
    };

    final uploadUri = Uri.parse(
      isUpdate
          ? 'https://www.googleapis.com/upload/drive/v3/files/${existing.id}?uploadType=multipart'
          : 'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
    );
    final streamed = await _sendStreamedWithRetry(() {
      final request =
          http.MultipartRequest(isUpdate ? 'PATCH' : 'POST', uploadUri)
            ..headers.addAll(authorizationHeaders)
            ..files.add(
              http.MultipartFile.fromString(
                'metadata',
                jsonEncode(metadata),
                filename: 'metadata.json',
              ),
            )
            ..files.add(
              http.MultipartFile.fromString(
                'file',
                content,
                filename: fileName,
              ),
            );
      return request.send();
    });
    final response = await http.Response.fromStream(streamed);
    _throwIfError(response);
  }

  Future<String> downloadTextFile({
    required Map<String, String> authorizationHeaders,
    required String fileId,
  }) async {
    final response = await _sendWithRetry(
      () => http.get(
        _filesUri.replace(
          path: '${_filesUri.path}/$fileId',
          queryParameters: const <String, String>{'alt': 'media'},
        ),
        headers: authorizationHeaders,
      ),
    );
    _throwIfError(response);
    return response.body;
  }

  Future<void> deleteFileOrFolder({
    required Map<String, String> authorizationHeaders,
    required String fileId,
  }) async {
    final response = await _sendWithRetry(
      () => http.delete(
        _filesUri.replace(path: '${_filesUri.path}/$fileId'),
        headers: authorizationHeaders,
      ),
    );
    _throwIfError(response, acceptNoContent: true);
  }

  Future<DriveFileResource> _ensureFolder({
    required Map<String, String> authorizationHeaders,
    required String folderName,
    String? parentId,
  }) async {
    final existing = await findChildByName(
      authorizationHeaders: authorizationHeaders,
      folderName: folderName,
      parentId: parentId,
      mimeType: _folderMimeType,
    );
    if (existing != null) {
      return existing;
    }

    final response = await _sendWithRetry(
      () => http.post(
        _filesUri,
        headers: <String, String>{
          ...authorizationHeaders,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'name': folderName,
          'mimeType': _folderMimeType,
          if (parentId != null) 'parents': <String>[parentId],
        }),
      ),
    );
    _throwIfError(response);
    return DriveFileResource.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() operation,
  ) async {
    var attempts = 0;
    while (true) {
      attempts++;
      try {
        final response = await operation();
        if (_isRetriableStatus(response.statusCode) && attempts < 3) {
          await Future<void>.delayed(Duration(seconds: attempts * 2));
          continue;
        }
        return response;
      } on SocketException {
        if (attempts >= 3) {
          rethrow;
        }
        await Future<void>.delayed(Duration(seconds: attempts * 2));
      } on TimeoutException {
        if (attempts >= 3) {
          rethrow;
        }
        await Future<void>.delayed(Duration(seconds: attempts * 2));
      }
    }
  }

  Future<http.StreamedResponse> _sendStreamedWithRetry(
    Future<http.StreamedResponse> Function() operation,
  ) async {
    var attempts = 0;
    while (true) {
      attempts++;
      try {
        final response = await operation();
        if (_isRetriableStatus(response.statusCode) && attempts < 3) {
          await Future<void>.delayed(Duration(seconds: attempts * 2));
          continue;
        }
        return response;
      } on SocketException {
        if (attempts >= 3) {
          rethrow;
        }
        await Future<void>.delayed(Duration(seconds: attempts * 2));
      } on TimeoutException {
        if (attempts >= 3) {
          rethrow;
        }
        await Future<void>.delayed(Duration(seconds: attempts * 2));
      }
    }
  }

  bool _isRetriableStatus(int statusCode) {
    return statusCode == 408 || statusCode == 429 || statusCode >= 500;
  }

  void _throwIfError(http.Response response, {bool acceptNoContent = false}) {
    if ((response.statusCode >= 200 && response.statusCode < 300) ||
        (acceptNoContent && response.statusCode == 204)) {
      return;
    }
    throw HttpException(
      'Google Drive request failed (${response.statusCode}): ${response.body}',
    );
  }

  String _escapeQueryValue(String value) {
    return value.replaceAll("'", r"\'");
  }
}
