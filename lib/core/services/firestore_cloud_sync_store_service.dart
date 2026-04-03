import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cloud_sync_models.dart';

class FirestoreCloudSyncStoreService {
  FirestoreCloudSyncStoreService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _usersCollection = 'users';
  static const String _cloudSyncCollection = 'cloud_sync';
  static const String _manifestDocId = 'manifest';
  static const String _credentialDocId = 'credential';
  static const String _expenseDocId = 'expense';
  static const String _taskDocId = 'task';

  final FirebaseFirestore _firestore;

  Future<void> uploadBundle({
    required String userId,
    required CloudBackupBundle bundle,
  }) async {
    final collection = _collection(userId);
    final batch = _firestore.batch();
    final timestamp = Timestamp.fromDate(bundle.manifest.exportedAt);

    batch.set(collection.doc(_manifestDocId), <String, dynamic>{
      ...bundle.manifest.toJson(),
      'updatedAt': timestamp,
    });
    if (bundle.containsCredentialPayload) {
      batch.set(collection.doc(_credentialDocId), <String, dynamic>{
        'payload': bundle.credentialPayload,
        'updatedAt': timestamp,
      });
    } else {
      batch.delete(collection.doc(_credentialDocId));
    }
    batch.set(collection.doc(_expenseDocId), <String, dynamic>{
      'payload': bundle.expensePayload,
      'updatedAt': timestamp,
    });
    batch.set(collection.doc(_taskDocId), <String, dynamic>{
      'payload': bundle.taskPayload,
      'updatedAt': timestamp,
    });
    await batch.commit();
  }

  Future<CloudSyncManifest?> getManifest(String userId) async {
    final snapshot = await _collection(userId).doc(_manifestDocId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }
    return CloudSyncManifest.fromJson(_normalizeMap(data));
  }

  Future<CloudBackupBundle?> getBundle(String userId) async {
    final collection = _collection(userId);
    final manifestSnapshot = await collection.doc(_manifestDocId).get();
    final credentialSnapshot = await collection.doc(_credentialDocId).get();
    final expenseSnapshot = await collection.doc(_expenseDocId).get();
    final taskSnapshot = await collection.doc(_taskDocId).get();

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
      updatedCounts[folderName] = 0;
      batch.set(collection.doc(_manifestDocId), <String, dynamic>{
        ...manifest
            .copyWith(
              exportedAt: DateTime.now(),
              localLatestAt: DateTime.now(),
              domainCounts: updatedCounts,
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
              return MapEntry(nestedKey.toString(), nestedValue.toDate().toIso8601String());
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
}
