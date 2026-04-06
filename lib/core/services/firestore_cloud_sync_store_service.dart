import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cloud_sync_models.dart';
import 'cancellable_task.dart';

class FirestoreCloudSyncStoreService {
  FirestoreCloudSyncStoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _usersCollection = 'users';
  static const String _cloudSyncCollection = 'cloud_sync';
  static const String _manifestDocId = 'manifest';
  static const String _credentialDocId = 'credential';
  static const String _expenseDocId = 'expense';
  static const String _taskDocId = 'task';
  static const String _settingsDocId = 'settings';

  final FirebaseFirestore _firestore;

  Future<CloudUploadResult> uploadBundle({
    required String userId,
    required CloudBackupBundle bundle,
    AppCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    final collection = _collection(userId);
    final snapshots =
        await Future.wait<DocumentSnapshot<Map<String, dynamic>>>([
          collection.doc(_manifestDocId).get(),
          collection.doc(_credentialDocId).get(),
          collection.doc(_expenseDocId).get(),
          collection.doc(_taskDocId).get(),
          collection.doc(_settingsDocId).get(),
        ]);
    cancellationToken?.throwIfCancelled();

    final manifestSnapshot = snapshots[0];
    final credentialSnapshot = snapshots[1];
    final expenseSnapshot = snapshots[2];
    final taskSnapshot = snapshots[3];
    final settingsSnapshot = snapshots[4];
    final manifestData = manifestSnapshot.data();
    final credentialData = credentialSnapshot.data();
    final expenseData = expenseSnapshot.data();
    final taskData = taskSnapshot.data();
    final settingsData = settingsSnapshot.data();
    final currentManifest = manifestSnapshot.exists && manifestData != null
        ? CloudSyncManifest.fromJson(_normalizeMap(manifestData))
        : null;

    final shouldUpdateCredential = _shouldUpdateDomain(
      currentManifest: currentManifest,
      domain: CloudSyncDomain.credential,
      remoteDocExists: credentialSnapshot.exists,
      shouldExistRemotely: bundle.containsCredentialPayload,
      nextHash: bundle.manifest.domainHashFor(
        CloudSyncDomain.credential.folderName,
      ),
      payloadFormatChanged: bundle.containsCredentialPayload
          ? _hasCredentialPayloadFormatChanged(
              currentPayload: credentialData?['payload'] as String?,
              nextPayload: bundle.credentialPayload,
            )
          : false,
    );
    final shouldUpdateExpense = _shouldUpdateDomain(
      currentManifest: currentManifest,
      domain: CloudSyncDomain.expense,
      remoteDocExists: expenseSnapshot.exists,
      shouldExistRemotely: true,
      nextHash: bundle.manifest.domainHashFor(
        CloudSyncDomain.expense.folderName,
      ),
      payloadFormatChanged: _hasProtectedPayloadFormatChanged(
        currentPayload: expenseData?['payload'] as String?,
        nextPayload: bundle.expensePayload,
      ),
    );
    final shouldUpdateTask = _shouldUpdateDomain(
      currentManifest: currentManifest,
      domain: CloudSyncDomain.task,
      remoteDocExists: taskSnapshot.exists,
      shouldExistRemotely: true,
      nextHash: bundle.manifest.domainHashFor(CloudSyncDomain.task.folderName),
      payloadFormatChanged: _hasProtectedPayloadFormatChanged(
        currentPayload: taskData?['payload'] as String?,
        nextPayload: bundle.taskPayload,
      ),
    );
    final shouldUpdateSettings = _shouldUpdateDomain(
      currentManifest: currentManifest,
      domain: CloudSyncDomain.settings,
      remoteDocExists: settingsSnapshot.exists,
      shouldExistRemotely: bundle.containsSettingsPayload,
      nextHash: bundle.manifest.domainHashFor(
        CloudSyncDomain.settings.folderName,
      ),
      payloadFormatChanged: bundle.containsSettingsPayload
          ? _hasProtectedPayloadFormatChanged(
              currentPayload: settingsData?['payload'] as String?,
              nextPayload: bundle.settingsPayload,
            )
          : false,
    );

    final shouldUpdateManifest =
        currentManifest == null ||
        shouldUpdateCredential ||
        shouldUpdateExpense ||
        shouldUpdateTask ||
        shouldUpdateSettings ||
        !_matchesStoredManifest(currentManifest, bundle.manifest);

    if (!shouldUpdateManifest &&
        !shouldUpdateCredential &&
        !shouldUpdateExpense &&
        !shouldUpdateTask &&
        !shouldUpdateSettings) {
      return CloudUploadResult(
        manifest: currentManifest,
        didWriteRemoteData: false,
      );
    }

    final batch = _firestore.batch();
    final timestamp = Timestamp.fromDate(bundle.manifest.exportedAt);
    final updatedDomains = <String>[];

    if (shouldUpdateManifest) {
      batch.set(collection.doc(_manifestDocId), <String, dynamic>{
        ...bundle.manifest.toJson(),
        'updatedAt': timestamp,
      });
    }

    if (shouldUpdateCredential) {
      if (bundle.containsCredentialPayload) {
        batch.set(collection.doc(_credentialDocId), <String, dynamic>{
          'payload': bundle.credentialPayload,
          'updatedAt': timestamp,
        });
      } else {
        batch.delete(collection.doc(_credentialDocId));
      }
      updatedDomains.add(CloudSyncDomain.credential.folderName);
    }

    if (shouldUpdateExpense) {
      batch.set(collection.doc(_expenseDocId), <String, dynamic>{
        'payload': bundle.expensePayload,
        'updatedAt': timestamp,
      });
      updatedDomains.add(CloudSyncDomain.expense.folderName);
    }

    if (shouldUpdateTask) {
      batch.set(collection.doc(_taskDocId), <String, dynamic>{
        'payload': bundle.taskPayload,
        'updatedAt': timestamp,
      });
      updatedDomains.add(CloudSyncDomain.task.folderName);
    }

    if (shouldUpdateSettings) {
      if (bundle.containsSettingsPayload) {
        batch.set(collection.doc(_settingsDocId), <String, dynamic>{
          'payload': bundle.settingsPayload,
          'updatedAt': timestamp,
        });
      } else {
        batch.delete(collection.doc(_settingsDocId));
      }
      updatedDomains.add(CloudSyncDomain.settings.folderName);
    }

    await batch.commit();
    cancellationToken?.throwIfCancelled();
    updatedDomains.sort();
    return CloudUploadResult(
      manifest: bundle.manifest,
      didWriteRemoteData: true,
      updatedDomains: updatedDomains,
    );
  }

  Future<CloudSyncManifest?> getManifest(
    String userId, {
    AppCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    final snapshot = await _collection(userId).doc(_manifestDocId).get();
    cancellationToken?.throwIfCancelled();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }
    return CloudSyncManifest.fromJson(_normalizeMap(data));
  }

  Future<CloudBackupBundle?> getBundle(
    String userId, {
    AppCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    final collection = _collection(userId);
    final snapshots =
        await Future.wait<DocumentSnapshot<Map<String, dynamic>>>([
          collection.doc(_manifestDocId).get(),
          collection.doc(_credentialDocId).get(),
          collection.doc(_expenseDocId).get(),
          collection.doc(_taskDocId).get(),
          collection.doc(_settingsDocId).get(),
        ]);
    cancellationToken?.throwIfCancelled();
    final manifestSnapshot = snapshots[0];
    final credentialSnapshot = snapshots[1];
    final expenseSnapshot = snapshots[2];
    final taskSnapshot = snapshots[3];
    final settingsSnapshot = snapshots[4];

    final manifestData = manifestSnapshot.data();
    final credentialData = credentialSnapshot.data();
    final expenseData = expenseSnapshot.data();
    final taskData = taskSnapshot.data();
    final settingsData = settingsSnapshot.data();
    if (!manifestSnapshot.exists ||
        !expenseSnapshot.exists ||
        !taskSnapshot.exists ||
        manifestData == null ||
        expenseData == null ||
        taskData == null) {
      return null;
    }

    final hasCredentialPayload =
        credentialSnapshot.exists && credentialData != null;
    final hasSettingsPayload = settingsSnapshot.exists && settingsData != null;

    return CloudBackupBundle(
      manifest: CloudSyncManifest.fromJson(_normalizeMap(manifestData)),
      credentialPayload: hasCredentialPayload
          ? credentialData['payload'] as String? ?? ''
          : _emptyCredentialPayload(),
      containsCredentialPayload: hasCredentialPayload,
      expensePayload: expenseData['payload'] as String? ?? '',
      taskPayload: taskData['payload'] as String? ?? '',
      settingsPayload: hasSettingsPayload
          ? settingsData['payload'] as String? ?? ''
          : _emptySettingsPayload(),
      containsSettingsPayload: hasSettingsPayload,
    );
  }

  Future<void> deleteCloudData({
    required String userId,
    required String folderName,
  }) async {
    final collection = _collection(userId);
    if (folderName == 'Daily Use') {
      final batch = _firestore.batch();
      for (final docId in <String>[
        _manifestDocId,
        _credentialDocId,
        _expenseDocId,
        _taskDocId,
        _settingsDocId,
      ]) {
        batch.delete(collection.doc(docId));
      }
      await batch.commit();
      return;
    }

    final domainDocId = switch (folderName) {
      'Credential' => _credentialDocId,
      'Expense' => _expenseDocId,
      'Task' => _taskDocId,
      'Settings' => _settingsDocId,
      _ => null,
    };
    if (domainDocId == null) {
      return;
    }

    final batch = _firestore.batch();
    batch.delete(collection.doc(domainDocId));

    final manifest = await getManifest(userId);
    if (manifest != null) {
      final updatedCounts = Map<String, int>.from(manifest.domainCounts);
      final updatedHashes = Map<String, String>.from(manifest.domainHashes);
      updatedCounts[folderName] = 0;
      updatedHashes[folderName] = '';
      batch.set(collection.doc(_manifestDocId), <String, dynamic>{
        ...manifest
            .copyWith(
              exportedAt: DateTime.now(),
              localLatestAt: DateTime.now(),
              domainCounts: updatedCounts,
              domainHashes: updatedHashes,
            )
            .toJson(),
        'updatedAt': Timestamp.now(),
      });
    }

    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_cloudSyncCollection);
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> source) {
    return source.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      }
      if (value is Map) {
        return MapEntry(
          key,
          value.map((nestedKey, nestedValue) {
            if (nestedValue is Timestamp) {
              return MapEntry(
                nestedKey.toString(),
                nestedValue.toDate().toIso8601String(),
              );
            }
            return MapEntry(nestedKey.toString(), nestedValue);
          }),
        );
      }
      return MapEntry(key, value);
    });
  }

  String _emptyCredentialPayload() {
    return '{"schemaVersion":0,"exportedAt":"","records":[]}';
  }

  String _emptySettingsPayload() {
    return '{"schemaVersion":0,"exportedAt":"","appSettings":{},"reminderSettings":{}}';
  }

  bool _shouldUpdateDomain({
    required CloudSyncManifest? currentManifest,
    required CloudSyncDomain domain,
    required bool remoteDocExists,
    required bool shouldExistRemotely,
    required String nextHash,
    required bool payloadFormatChanged,
  }) {
    final folderName = domain.folderName;
    final currentHash = currentManifest?.domainHashFor(folderName) ?? '';
    final hashChanged = currentHash != nextHash;
    final presenceChanged = shouldExistRemotely
        ? !remoteDocExists
        : remoteDocExists;
    final currentCount = currentManifest?.domainCounts[folderName] ?? -1;
    final expectsEmptyCount = !shouldExistRemotely && currentCount != 0;
    return currentManifest == null ||
        hashChanged ||
        presenceChanged ||
        expectsEmptyCount ||
        payloadFormatChanged;
  }

  bool _hasCredentialPayloadFormatChanged({
    required String? currentPayload,
    required String nextPayload,
  }) {
    if (currentPayload == null || currentPayload.isEmpty) {
      return true;
    }
    return _credentialPayloadSchemaVersion(currentPayload) !=
        _credentialPayloadSchemaVersion(nextPayload);
  }

  bool _hasProtectedPayloadFormatChanged({
    required String? currentPayload,
    required String nextPayload,
  }) {
    if (currentPayload == null || currentPayload.isEmpty) {
      return true;
    }
    return _protectedPayloadFormatSignature(currentPayload) !=
        _protectedPayloadFormatSignature(nextPayload);
  }

  int _credentialPayloadSchemaVersion(String payload) {
    try {
      final decoded = _decodedPayloadMap(payload);
      final schemaVersion = decoded['schemaVersion'];
      return schemaVersion is int ? schemaVersion : -1;
    } catch (_) {
      return -1;
    }
  }

  String _protectedPayloadFormatSignature(String payload) {
    try {
      final decoded = _decodedPayloadMap(payload);
      if (decoded['encrypted'] == true) {
        final schemaVersion = decoded['schemaVersion'];
        return 'encrypted:${schemaVersion is int ? schemaVersion : -1}';
      }
      return 'plain';
    } catch (_) {
      return 'invalid';
    }
  }

  Map<String, dynamic> _decodedPayloadMap(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } catch (_) {
      return <String, dynamic>{};
    }
    return <String, dynamic>{};
  }

  bool _matchesStoredManifest(
    CloudSyncManifest current,
    CloudSyncManifest next,
  ) {
    return current.schemaVersion == next.schemaVersion &&
        current.localLatestAt == next.localLatestAt &&
        current.accountEmail == next.accountEmail &&
        current.payloadEncryptionSchemaVersion ==
            next.payloadEncryptionSchemaVersion &&
        current.cloudKeyFormatVersion == next.cloudKeyFormatVersion &&
        _intMapEquals(current.domainCounts, next.domainCounts) &&
        _stringMapEquals(current.domainHashes, next.domainHashes);
  }

  bool _intMapEquals(Map<String, int> left, Map<String, int> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  bool _stringMapEquals(Map<String, String> left, Map<String, String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
