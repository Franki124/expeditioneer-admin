import 'package:cloud_firestore/cloud_firestore.dart';

class AdminParticipant {
  const AdminParticipant({
    required this.uid,
    required this.displayName,
    required this.joinedAt,
    required this.collectedCount,
    this.lastScanAt,
    this.completedAt,
    this.totalPoints = 0,
    this.bonusPoints = 0,
  });

  final String uid;
  final String displayName;
  final DateTime joinedAt;
  final int collectedCount;
  final DateTime? lastScanAt;
  final DateTime? completedAt;
  final int totalPoints;
  final int bonusPoints;

  factory AdminParticipant.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AdminParticipant(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      collectedCount: (data['collectedCount'] as num?)?.toInt() ?? 0,
      lastScanAt: (data['lastScanAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
      bonusPoints: (data['bonusPoints'] as num?)?.toInt() ?? 0,
    );
  }
}
