import 'dart:convert';

import 'package:equatable/equatable.dart';

enum CloudSyncDomain { credential, expense, task, settings }

extension CloudSyncDomainX on CloudSyncDomain {
  String get folderName {
    switch (this) {
      case CloudSyncDomain.credential:
        return 'Credential';
      case CloudSyncDomain.expense:
        return 'Expense';
      case CloudSyncDomain.task:
        return 'Task';
      case CloudSyncDomain.settings:
        return 'Settings';
    }
  }

  String get fileName {
    switch (this) {
      case CloudSyncDomain.credential:
        return 'credentials.enc.json';
      case CloudSyncDomain.expense:
        return 'expense.json';
      case CloudSyncDomain.task:
        return 'task.json';
      case CloudSyncDomain.settings:
        return 'settings.json';
    }
  }
}

class CloudSyncManifest extends Equatable {
  const CloudSyncManifest({
    required this.schemaVersion,
    required this.exportedAt,
    required this.localLatestAt,
    required this.accountEmail,
    required this.domainCounts,
    required this.domainHashes,
  });

  final int schemaVersion;
  final DateTime exportedAt;
  final DateTime localLatestAt;
  final String? accountEmail;
  final Map<String, int> domainCounts;
  final Map<String, String> domainHashes;

  CloudSyncManifest copyWith({
    int? schemaVersion,
    DateTime? exportedAt,
    DateTime? localLatestAt,
    Object? accountEmail = _cloudSyncUnset,
    Map<String, int>? domainCounts,
    Map<String, String>? domainHashes,
  }) {
    return CloudSyncManifest(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      exportedAt: exportedAt ?? this.exportedAt,
      localLatestAt: localLatestAt ?? this.localLatestAt,
      accountEmail: identical(accountEmail, _cloudSyncUnset)
          ? this.accountEmail
          : accountEmail as String?,
      domainCounts: domainCounts ?? this.domainCounts,
      domainHashes: domainHashes ?? this.domainHashes,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': schemaVersion,
    'exportedAt': exportedAt.toIso8601String(),
    'localLatestAt': localLatestAt.toIso8601String(),
    'accountEmail': accountEmail,
    'domainCounts': domainCounts,
    'domainHashes': domainHashes,
  };

  factory CloudSyncManifest.fromJson(Map<String, dynamic> json) {
    final counts = json['domainCounts'];
    final hashes = json['domainHashes'];
    return CloudSyncManifest(
      schemaVersion: json['schemaVersion'] is int
          ? json['schemaVersion'] as int
          : 1,
      exportedAt:
          DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      localLatestAt:
          DateTime.tryParse(json['localLatestAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      accountEmail: json['accountEmail'] as String?,
      domainCounts: counts is Map
          ? counts.map(
              (key, value) =>
                  MapEntry(key.toString(), value is int ? value : 0),
            )
          : const <String, int>{},
      domainHashes: hashes is Map
          ? hashes.map(
              (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
            )
          : const <String, String>{},
    );
  }

  static CloudSyncManifest fromEncoded(String content) {
    return CloudSyncManifest.fromJson(
      jsonDecode(content) as Map<String, dynamic>,
    );
  }

  String encode() => jsonEncode(toJson());

  String domainHashFor(String folderName) => domainHashes[folderName] ?? '';

  @override
  List<Object?> get props => <Object?>[
    schemaVersion,
    exportedAt,
    localLatestAt,
    accountEmail,
    domainCounts,
    domainHashes,
  ];
}

const Object _cloudSyncUnset = Object();

class CloudRestoreCheck extends Equatable {
  const CloudRestoreCheck({
    required this.localLatestAt,
    required this.remoteLatestAt,
    required this.remoteManifest,
  });

  final DateTime localLatestAt;
  final DateTime remoteLatestAt;
  final CloudSyncManifest remoteManifest;

  bool get isLocalNewer => localLatestAt.isAfter(remoteLatestAt);

  @override
  List<Object?> get props => <Object?>[
    localLatestAt,
    remoteLatestAt,
    remoteManifest,
  ];
}

class CloudFileResource extends Equatable {
  const CloudFileResource({
    required this.id,
    required this.name,
    required this.mimeType,
    this.modifiedTime,
    this.parents = const <String>[],
  });

  final String id;
  final String name;
  final String mimeType;
  final DateTime? modifiedTime;
  final List<String> parents;

  factory CloudFileResource.fromJson(Map<String, dynamic> json) {
    return CloudFileResource(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? '',
      modifiedTime: DateTime.tryParse(json['modifiedTime'] as String? ?? ''),
      parents: (json['parents'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    mimeType,
    modifiedTime,
    parents,
  ];
}

class CloudBackupBundle extends Equatable {
  const CloudBackupBundle({
    required this.manifest,
    required this.credentialPayload,
    required this.containsCredentialPayload,
    required this.expensePayload,
    required this.taskPayload,
    required this.settingsPayload,
    required this.containsSettingsPayload,
  });

  final CloudSyncManifest manifest;
  final String credentialPayload;
  final bool containsCredentialPayload;
  final String expensePayload;
  final String taskPayload;
  final String settingsPayload;
  final bool containsSettingsPayload;

  @override
  List<Object?> get props => <Object?>[
    manifest,
    credentialPayload,
    containsCredentialPayload,
    expensePayload,
    taskPayload,
    settingsPayload,
    containsSettingsPayload,
  ];
}

class EncryptedCloudPayload extends Equatable {
  const EncryptedCloudPayload({
    required this.encryptedPayload,
    required this.saltBase64,
    required this.nonceBase64,
  });

  final String encryptedPayload;
  final String saltBase64;
  final String nonceBase64;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'encryptedPayload': encryptedPayload,
    'saltBase64': saltBase64,
    'nonceBase64': nonceBase64,
  };

  factory EncryptedCloudPayload.fromJson(Map<String, dynamic> json) {
    return EncryptedCloudPayload(
      encryptedPayload: json['encryptedPayload'] as String? ?? '',
      saltBase64: json['saltBase64'] as String? ?? '',
      nonceBase64: json['nonceBase64'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[
    encryptedPayload,
    saltBase64,
    nonceBase64,
  ];
}

class CloudUploadResult extends Equatable {
  const CloudUploadResult({
    required this.manifest,
    required this.didWriteRemoteData,
    this.updatedDomains = const <String>[],
  });

  final CloudSyncManifest manifest;
  final bool didWriteRemoteData;
  final List<String> updatedDomains;

  @override
  List<Object?> get props => <Object?>[
    manifest,
    didWriteRemoteData,
    updatedDomains,
  ];
}

class CloudCredentialEncryptionKeyRequiredException implements Exception {
  const CloudCredentialEncryptionKeyRequiredException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CloudCredentialEncryptionKeyInvalidException implements Exception {
  const CloudCredentialEncryptionKeyInvalidException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CloudPayloadDecryptionException implements Exception {
  const CloudPayloadDecryptionException(this.message);

  final String message;

  @override
  String toString() => message;
}
