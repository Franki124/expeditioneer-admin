import 'package:equatable/equatable.dart';

import '../domain/admin_profile.dart';

enum AdminAuthStatus { unknown, authenticated, unauthenticated }

class AdminAuthState extends Equatable {
  const AdminAuthState({
    this.status = AdminAuthStatus.unknown,
    this.profile,
    this.errorMessage,
  });

  final AdminAuthStatus status;
  final AdminProfile? profile;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, profile?.uid, errorMessage];
}
