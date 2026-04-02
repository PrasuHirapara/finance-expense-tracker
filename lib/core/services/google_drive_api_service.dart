import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../models/cloud_sync_models.dart';

class GoogleDriveApiService {
  GoogleDriveApiService();

  static const String appFolderName = 'Daily Use';
  static const String _folderMimeType = 'application/vnd.google-apps.folder';

  Future<Map<String, String>> ensureFolderHierarchy(
    Map<String, String> authorizationHeaders,
  ) async {
    return _withDriveApi(authorizationHeaders, (api) async {
      final root = await _ensureFolder(api: api, folderName: appFolderName);
      final credential = await _ensureFolder(
        api: api,
        folderName: CloudSyncDomain.credential.folderName,
        parentId: root.id,
      );
      final expense = await _ensureFolder(
        api: api,
        folderName: CloudSyncDomain.expense.folderName,
        parentId: root.id,
      );
      final task = await _ensureFolder(
        api: api,
        folderName: CloudSyncDomain.task.folderName,
        parentId: root.id,
      );

      return <String, String>{
        appFolderName: root.id,
        CloudSyncDomain.credential.folderName: credential.id,
        CloudSyncDomain.expense.folderName: expense.id,
        CloudSyncDomain.task.folderName: task.id,
      };
    });
  }

  Future<DriveFileResource?> findChildByName({
    required Map<String, String> authorizationHeaders,
    required String folderName,
    String? parentId,
    String? mimeType,
  }) async {
    return _withDriveApi(authorizationHeaders, (api) async {
      final queryParts = <String>[
        "name = '${_escapeQueryValue(folderName)}'",
        'trashed = false',
        if (parentId != null) "'$parentId' in parents",
        if (mimeType != null) "mimeType = '${_escapeQueryValue(mimeType)}'",
      ];

      final fileList = await _sendWithRetry(
        () => api.files.list(
          q: queryParts.join(' and '),
          $fields: 'files(id,name,mimeType,modifiedTime,parents)',
          pageSize: 10,
        ),
      );
      final files = fileList.files;
      if (files == null || files.isEmpty) {
        return null;
      }
      return _toDriveFileResource(files.first);
    });
  }

  Future<void> uploadTextFile({
    required Map<String, String> authorizationHeaders,
    required String parentId,
    required String fileName,
    required String content,
  }) async {
    return _withDriveApi(authorizationHeaders, (api) async {
      final existing = await _findChildByNameWithApi(
        api: api,
        folderName: fileName,
        parentId: parentId,
      );
      final bytes = Uint8List.fromList(utf8.encode(content));
      final media = drive.Media(Stream<List<int>>.value(bytes), bytes.length);
      final file = drive.File()
        ..name = fileName
        ..parents = existing == null ? <String>[parentId] : null;

      await _sendWithRetry(() {
        if (existing != null) {
          return api.files.update(file, existing.id, uploadMedia: media);
        }
        return api.files.create(file, uploadMedia: media);
      });
    });
  }

  Future<String> downloadTextFile({
    required Map<String, String> authorizationHeaders,
    required String fileId,
  }) async {
    return _withDriveApi(authorizationHeaders, (api) async {
      final media = await _sendWithRetry(
        () => api.files.get(
          fileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ),
      );
      final downloaded = media as drive.Media;
      final bytes = await downloaded.stream.fold<List<int>>(<int>[], (
        buffer,
        chunk,
      ) {
        buffer.addAll(chunk);
        return buffer;
      });
      return utf8.decode(bytes);
    });
  }

  Future<void> deleteFileOrFolder({
    required Map<String, String> authorizationHeaders,
    required String fileId,
  }) async {
    return _withDriveApi(authorizationHeaders, (api) async {
      await _sendWithRetry(() => api.files.delete(fileId));
    });
  }

  Future<DriveFileResource> _ensureFolder({
    required drive.DriveApi api,
    required String folderName,
    String? parentId,
  }) async {
    final existing = await _findChildByNameWithApi(
      api: api,
      folderName: folderName,
      parentId: parentId,
      mimeType: _folderMimeType,
    );
    if (existing != null) {
      return existing;
    }

    final folder = await _sendWithRetry(
      () => api.files.create(
        drive.File()
          ..name = folderName
          ..mimeType = _folderMimeType
          ..parents = parentId == null ? null : <String>[parentId],
      ),
    );
    return _toDriveFileResource(folder);
  }

  Future<DriveFileResource?> _findChildByNameWithApi({
    required drive.DriveApi api,
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
    final fileList = await _sendWithRetry(
      () => api.files.list(
        q: queryParts.join(' and '),
        $fields: 'files(id,name,mimeType,modifiedTime,parents)',
        pageSize: 10,
      ),
    );
    final files = fileList.files;
    if (files == null || files.isEmpty) {
      return null;
    }
    return _toDriveFileResource(files.first);
  }

  Future<T> _withDriveApi<T>(
    Map<String, String> authorizationHeaders,
    Future<T> Function(drive.DriveApi api) action,
  ) async {
    final client = _GoogleAuthHttpClient(authorizationHeaders);
    try {
      return await action(drive.DriveApi(client));
    } finally {
      client.close();
    }
  }

  Future<T> _sendWithRetry<T>(Future<T> Function() operation) async {
    var attempts = 0;
    while (true) {
      attempts++;
      try {
        return await operation();
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
      } on drive.DetailedApiRequestError catch (error) {
        if (!_isRetriableStatus(error.status ?? 0) || attempts >= 3) {
          rethrow;
        }
        await Future<void>.delayed(Duration(seconds: attempts * 2));
      }
    }
  }

  bool _isRetriableStatus(int statusCode) {
    return statusCode == 408 || statusCode == 429 || statusCode >= 500;
  }

  String _escapeQueryValue(String value) {
    return value.replaceAll("'", r"\'");
  }

  DriveFileResource _toDriveFileResource(drive.File file) {
    return DriveFileResource(
      id: file.id ?? '',
      name: file.name ?? '',
      mimeType: file.mimeType ?? '',
      modifiedTime: file.modifiedTime,
      parents: file.parents ?? const <String>[],
    );
  }
}

class _GoogleAuthHttpClient extends http.BaseClient {
  _GoogleAuthHttpClient(this._authorizationHeaders, [http.Client? inner])
    : _inner = inner ?? http.Client();

  final Map<String, String> _authorizationHeaders;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_authorizationHeaders);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}
