import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEvent {
  const AdminEvent({
    required this.id,
    required this.name,
    required this.location,
    required this.joinCode,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.journalCount,
    required this.createdBy,
    required this.createdAt,
    this.maxParticipants,
  });

  final String id;
  final String name;
  final String location;
  final String joinCode;
  final DateTime startAt;
  final DateTime endAt;
  final String status; // draft | live | closed | archived
  final int journalCount;
  final String createdBy;
  final DateTime createdAt;
  final int? maxParticipants;

  bool get isLive => status == 'live';

  factory AdminEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AdminEvent(
      id: doc.id,
      name: data['name'] as String? ?? '',
      location: data['location'] as String? ?? '',
      joinCode: data['joinCode'] as String? ?? '',
      startAt: (data['startAt'] as Timestamp).toDate(),
      endAt: (data['endAt'] as Timestamp).toDate(),
      status: data['status'] as String? ?? 'draft',
      journalCount: (data['journalCount'] as num?)?.toInt() ?? 0,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxParticipants: (data['maxParticipants'] as num?)?.toInt(),
    );
  }
}
