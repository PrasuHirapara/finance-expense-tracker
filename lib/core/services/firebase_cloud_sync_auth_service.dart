import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseCloudSyncAuthService {
  FirebaseCloudSyncAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _usersCollection = 'users';

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  bool _initialized = false;

  bool get isAvailable => Firebase.apps.isNotEmpty;

  FirebaseCloudSyncAccount? get currentAccount {
    final user = _firebaseAuth.currentUser;
    return user == null ? null : FirebaseCloudSyncAccount.fromUser(user);
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    if (Firebase.apps.isEmpty) {
      throw const FirebaseCloudSyncAuthConfigurationException(
        'Firebase is not initialized. Add Firebase setup before using cloud sync.',
      );
    }
    await _googleSignIn.initialize();
    _initialized = true;
  }

  Stream<FirebaseCloudSyncAccount?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((user) {
      return user == null ? null : FirebaseCloudSyncAccount.fromUser(user);
    });
  }

  Future<FirebaseCloudSyncAccount?> restoreSession() async {
    await initialize();
    var user = _firebaseAuth.currentUser;
    if (user == null) {
      try {
        user = await _firebaseAuth
            .authStateChanges()
            .first
            .timeout(const Duration(seconds: 5));
      } on TimeoutException {
        user = _firebaseAuth.currentUser;
      }
    }
    return user == null ? null : FirebaseCloudSyncAccount.fromUser(user);
  }

  Future<FirebaseCloudSyncAccount> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await initialize();
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = userCredential.user;
    if (user == null) {
      throw StateError('Unable to sign in with email and password.');
    }
    await _upsertUserProfile(user);
    return FirebaseCloudSyncAccount.fromUser(user);
  }

  Future<FirebaseCloudSyncAccount> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await initialize();
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    var user = userCredential.user;
    if (user == null) {
      throw StateError('Unable to create the Firebase account.');
    }

    final trimmedDisplayName = displayName?.trim();
    if (trimmedDisplayName != null && trimmedDisplayName.isNotEmpty) {
      await user.updateDisplayName(trimmedDisplayName);
      await user.reload();
      user = _firebaseAuth.currentUser ?? user;
    }

    await _upsertUserProfile(user);
    return FirebaseCloudSyncAccount.fromUser(user);
  }

  Future<FirebaseCloudSyncAccount> signInWithGoogle() async {
    await initialize();
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw StateError('Google account authentication was cancelled.');
    }
    await _upsertUserProfile(user);
    return FirebaseCloudSyncAccount.fromUser(user);
  }

  Future<FirebaseCloudSyncAccount> authenticateInteractively() {
    return signInWithGoogle();
  }

  Future<FirebaseCloudSyncAccount> requireUser({
    required bool interactive,
  }) async {
    final account = await restoreSession();
    if (account == null) {
      throw StateError(
        interactive
            ? 'No signed-in Firebase account is available.'
            : 'No active signed-in account is available for background sync.',
      );
    }
    return account;
  }

  Future<String?> currentUserEmail({required bool interactive}) async {
    final account = await requireUser(interactive: interactive);
    return account.email;
  }

  Future<String?> restoreCurrentUserEmail() async {
    final account = await restoreSession();
    return account?.email;
  }

  Future<String?> currentUserId({required bool interactive}) async {
    final account = await requireUser(interactive: interactive);
    return account.uid;
  }

  Future<void> signOut() async {
    await initialize();
    await _firebaseAuth.signOut();
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      await _googleSignIn.signOut();
    }
  }

  Future<void> _upsertUserProfile(User user) async {
    final doc = _firestore.collection(_usersCollection).doc(user.uid);
    final snapshot = await doc.get();
    final providers =
        user.providerData
            .map((provider) => provider.providerId)
            .where((providerId) => providerId.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final data = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'providers': providers,
      'lastSignInAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await doc.set(data, SetOptions(merge: true));
  }
}

class FirebaseCloudSyncAccount {
  const FirebaseCloudSyncAccount({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.providerIds,
  });

  factory FirebaseCloudSyncAccount.fromUser(User user) {
    return FirebaseCloudSyncAccount(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      providerIds:
          user.providerData
              .map((provider) => provider.providerId)
              .where((providerId) => providerId.isNotEmpty)
              .toSet()
              .toList()
            ..sort(),
    );
  }

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final List<String> providerIds;
}

class FirebaseCloudSyncAuthConfigurationException implements Exception {
  const FirebaseCloudSyncAuthConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}
