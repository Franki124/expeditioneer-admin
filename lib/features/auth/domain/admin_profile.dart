import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfile {
  const AdminProfile({
    required this.uid,
    required this.role,
    required this.managedEventIds,
  });

  final String uid;
  final String role; // 'admin' | 'superadmin'
  final List<String> managedEventIds;

  factory AdminProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AdminProfile(
      uid: doc.id,
      role: data['role'] as String? ?? 'admin',
      managedEventIds:
          (data['managedEventIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
