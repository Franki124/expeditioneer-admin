import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/admin_profile.dart';

class AdminAuthRepository {
  AdminAuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  Future<void> signInWithEmail(String email, String password) {
    return _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  /// Reads `admins/{uid}` to check admin status. Returns null if the
  /// signed-in account has no admin doc — the caller should sign it back out.
  Future<AdminProfile?> fetchAdminProfile(String uid) async {
    final doc = await _firestore.collection('admins').doc(uid).get();
    if (!doc.exists) return null;
    return AdminProfile.fromDoc(doc);
  }
}
