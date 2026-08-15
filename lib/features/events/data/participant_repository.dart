import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/admin_participant.dart';

class ParticipantRepository {
  ParticipantRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _participants(String eventId) => _firestore
      .collection('events')
      .doc(eventId)
      .collection('participants');

  /// Same ordering as the player app's leaderboard query.
  Stream<List<AdminParticipant>> watchLeaderboard(String eventId, {int limit = 50}) {
    return _participants(eventId)
        .orderBy('totalPoints', descending: true)
        .orderBy('lastScanAt')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AdminParticipant.fromDoc).toList());
  }

  Stream<List<AdminParticipant>> watchParticipants(String eventId) {
    return _participants(eventId)
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AdminParticipant.fromDoc).toList());
  }

  /// Grants a manual point adjustment. Tracked separately in `bonusPoints`
  /// (rather than folded silently into `totalPoints`) so the Participants
  /// table can show it was admin-granted, not quest-earned — `totalPoints`
  /// still drives ranking either way. [points] may be negative to correct an
  /// earlier grant.
  Future<void> grantBonusPoints({
    required String eventId,
    required String participantId,
    required int points,
  }) {
    return _participants(eventId).doc(participantId).update({
      'bonusPoints': FieldValue.increment(points),
      'totalPoints': FieldValue.increment(points),
    });
  }
}
