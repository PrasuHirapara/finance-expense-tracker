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
        ]);
    cancellationToken?.throwIfCancelled();

    final manifestSnapshot = snapshots[0];
    final credentialSnapshot = snapshots[1];
    final expenseSnapshot = snapshots[2];
    final taskSnapshot = snapshots[3];
    final manifestData = manifestSnapshot.data();
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
    );
    final shouldUpdateExpense = _shouldUpdateDomain(
      currentManifest: currentManifest,
      domain: CloudSyncDomain.expense,
      remoteDocExists: expenseSnapshot.exists,
      shouldExistRemotely: true,
      nextHash: bundle.manifest.domainHashFor(
        CloudSyncDomain.expense.folderName,
      ),
    );
    final shouldUpdateTask = _shouldUpdateDomain(
      currentManifest: currentManifest,
      domain: CloudSyncDomain.task,
      remoteDocExists: taskSnapshot.exists,
      shouldExistRemotely: true,
      nextHash: bundle.manifest.domainHashFor(CloudSyncDomain.task.folderName),
    );

    final shouldUpdateManifest =
        currentManifest == null ||
        shouldUpdateCredential ||
        shouldUpdateExpense ||
        shouldUpdateTask ||
        !_matchesStoredManifest(currentManifest, bundle.manifest);

    if (!shouldUpdateManifest &&
        !shouldUpdateCredential &&
        !shouldUpdateExpense &&
        !shouldUpdateTask) {
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
        ]);
    cancellationToken?.throwIfCancelled();
    final manifestSnapshot = snapshots[0];
    final credentialSnapshot = snapshots[1];
    final expenseSnapshot = snapshots[2];
    final taskSnapshot = snapshots[3];

    final manifestData = manifestSnapshot.data();
    final credentialData = credentialSnapshot.data();
    final expenseData = expenseSnapshot.data();
    final taskData = taskSnapshot.data();

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

    return CloudBackupBundle(
      manifest: CloudSyncManifest.fromJson(_normalizeMap(manifestData)),
      credentialPayload: hasCredentialPayload
          ? credentialData['payload'] as String? ?? ''
          : _emptyCredentialPayload(),
      containsCredentialPayload: hasCredentialPayload,
      expensePayload: expenseData['payload'] as String? ?? '',
      taskPayload: taskData['payload'] as String? ?? '',
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

  bool _shouldUpdateDomain({
    required CloudSyncManifest? currentManifest,
    required CloudSyncDomain domain,
    required bool remoteDocExists,
    required bool shouldExistRemotely,
    required String nextHash,
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
        expectsEmptyCount;
  }

  bool _matchesStoredManifest(
    CloudSyncManifest current,
    CloudSyncManifest next,
  ) {
    return current.schemaVersion == next.schemaVersion &&
        current.localLatestAt == next.localLatestAt &&
        current.accountEmail == next.accountEmail &&
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
