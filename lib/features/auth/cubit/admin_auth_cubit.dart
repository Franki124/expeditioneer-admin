import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/admin_auth_repository.dart';
import 'admin_auth_state.dart';

class AdminAuthCubit extends Cubit<AdminAuthState> {
  AdminAuthCubit(this._repository) : super(const AdminAuthState()) {
    _subscription = _repository.authStateChanges().listen(_onAuthChanged);
  }

  final AdminAuthRepository _repository;
  late final StreamSubscription<User?> _subscription;

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      emit(const AdminAuthState(status: AdminAuthStatus.unauthenticated));
      return;
    }
    try {
      final profile = await _repository.fetchAdminProfile(user.uid);
      if (profile == null) {
        await _repository.signOut();
        emit(const AdminAuthState(
          status: AdminAuthStatus.unauthenticated,
          errorMessage: 'This account is not registered as an admin.',
        ));
        return;
      }
      emit(AdminAuthState(status: AdminAuthStatus.authenticated, profile: profile));
    } catch (_) {
      await _repository.signOut();
      emit(const AdminAuthState(
        status: AdminAuthStatus.unauthenticated,
        errorMessage: 'Could not verify admin access. Please try again.',
      ));
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _repository.signInWithEmail(email.trim(), password);
    } on FirebaseAuthException catch (e) {
      emit(AdminAuthState(
        status: state.status,
        profile: state.profile,
        errorMessage: _messageFor(e),
      ));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _repository.sendPasswordResetEmail(email.trim());
      emit(AdminAuthState(
        status: state.status,
        profile: state.profile,
        errorMessage: 'Password reset email sent.',
      ));
    } on FirebaseAuthException catch (_) {
      emit(AdminAuthState(
        status: state.status,
        profile: state.profile,
        errorMessage: 'Could not send reset email. Check the address and try again.',
      ));
    }
  }

  Future<void> signOut() => _repository.signOut();

  void clearError() => emit(AdminAuthState(status: state.status, profile: state.profile));

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
